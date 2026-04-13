#include <Arduino.h>
#include <TFT_eSPI.h>
#include <SPI.h>
#include <WiFi.h>
#include <HTTPClient.h>

TFT_eSPI tft = TFT_eSPI();

// --- Pines AD8232 ---
#define ECG_PIN   34
#define LO_PLUS   32
#define LO_MINUS  33

// --- Colores ---
#define COLOR_BG       0x0000
#define COLOR_PINK     0xF81F
#define COLOR_GREEN    0x07E0
#define COLOR_RED      0xF800
#define COLOR_GRAY     0x8410
#define COLOR_WHITE    0xFFFF
#define COLOR_YELLOW   0xFFE0
#define COLOR_DARKGRAY 0x2104
#define COLOR_CYAN     0x07FF

// --- Gráfica ---
#define GRAPH_X   5
#define GRAPH_Y   5
#define GRAPH_W   310
#define GRAPH_H   155
#define GRAPH_MID (GRAPH_Y + GRAPH_H / 2)

// --- Panel inferior ---
#define PANEL_Y 168

// --- Variables ECG ---
int graphIndex = 0;
int prevY      = GRAPH_MID;

// --- BPM ---
unsigned long lastBeatTime   = 0;
int           bpm            = 0;
int           lastSample     = 0;
bool          rising         = false;
#define BPM_THRESHOLD    2500
#define BPM_MIN_INTERVAL 400

// --- Amplitud ---
int sigMin    = 4095;
int sigMax    = 0;
int amplitude = 0;

// --- Cronómetro ---
unsigned long startTime = 0;

// --- Estado ---
String   estado      = "Normal";
uint16_t estadoColor = COLOR_GREEN;

// --- Electrodo ---
bool electrodeOk = true;

// --- WiFi ---
const char* ssid     = "BlackRubick Room";
const char* password = "Cuco2023**";
const char* serverUrl = "http://192.168.3.44:5000/api/datos";

// -------------------------------------------------------
// ANIMACIÓN TYPEWRITER
// -------------------------------------------------------
void drawCursor(int x, int y, bool visible, int font) {
  uint16_t color = visible ? COLOR_PINK : COLOR_BG;
  int fh = (font == 4) ? 26 : 14;
  tft.fillRect(x, y, 3, fh, color);
}

int typewriterWrite(const char* text, int cx, int baseY, int font,
                    uint16_t color, int charDelay) {
  int totalW = tft.textWidth(text, font);
  int startX = cx - totalW / 2;

  char buf[64] = {0};
  int  len     = strlen(text);

  for (int i = 0; i < len; i++) {
    buf[i] = text[i];
    tft.fillRect(startX, baseY, totalW + 6, tft.fontHeight(font) + 2, COLOR_BG);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(color, COLOR_BG);
    tft.drawString(buf, startX, baseY, font);

    int writtenW = tft.textWidth(buf, font);
    for (int b = 0; b < 2; b++) {
      drawCursor(startX + writtenW + 1, baseY, true,  font);
      delay(charDelay / 2);
      drawCursor(startX + writtenW + 1, baseY, false, font);
      delay(charDelay / 2);
    }
  }

  // Cursor final parpadeando
  int writtenW = tft.textWidth(text, font);
  for (int b = 0; b < 3; b++) {
    drawCursor(startX + writtenW + 1, baseY, true,  font);
    delay(200);
    drawCursor(startX + writtenW + 1, baseY, false, font);
    delay(200);
  }

  return startX;
}

void typewriterErase(const char* text, int startX, int baseY, int font,
                     int charDelay) {
  char buf[64];
  strncpy(buf, text, sizeof(buf));
  int len = strlen(buf);
  int fh  = tft.fontHeight(font);

  for (int i = len; i >= 0; i--) {
    buf[i] = '\0';
    tft.fillRect(startX, baseY, tft.textWidth(text, font) + 10, fh + 2, COLOR_BG);
    if (i > 0) {
      tft.setTextDatum(TL_DATUM);
      tft.setTextColor(COLOR_PINK, COLOR_BG);
      tft.drawString(buf, startX, baseY, font);

      int writtenW = tft.textWidth(buf, font);
      drawCursor(startX + writtenW + 1, baseY, true, font);
      delay(charDelay);
      drawCursor(startX + writtenW + 1, baseY, false, font);
    }
  }
}

// -------------------------------------------------------
// ONDA QRS — forma PQRST realista, centrada y grande
// -------------------------------------------------------
static const int   QN   = 14;
static const float QNX[QN] = {
  0.00f, 0.08f, 0.18f, 0.26f, 0.32f, 0.36f,
  0.40f, 0.44f, 0.50f, 0.60f, 0.70f, 0.82f,
  0.92f, 1.00f
};
static const int QNY[QN] = {
  0,  0, -8, -10, -8,  34,
  -47, -8,  8,   6, -12,   0,
  0,  0
};

void drawQRS(int baseY, int totalW, int startX, uint16_t color, int segDelay) {
  int px[QN], py[QN];
  for (int i = 0; i < QN; i++) {
    px[i] = startX + (int)(QNX[i] * totalW);
    py[i] = baseY  + QNY[i];
  }
  for (int i = 0; i < QN - 1; i++) {
    int steps = 5;
    for (int s = 0; s < steps; s++) {
      int x0 = px[i] + (px[i+1] - px[i]) * s       / steps;
      int y0 = py[i] + (py[i+1] - py[i]) * s       / steps;
      int x1 = px[i] + (px[i+1] - px[i]) * (s + 1) / steps;
      int y1 = py[i] + (py[i+1] - py[i]) * (s + 1) / steps;
      tft.drawLine(x0, y0,     x1, y1,     color);
      tft.drawLine(x0, y0 + 1, x1, y1 + 1, color); // grosor 2px
    }
    delay(segDelay);
  }
}

void eraseQRS(int baseY, int totalW, int startX, int amp) {
  for (int x = startX - 2; x <= startX + totalW + 4; x += 3) {
    tft.drawFastVLine(x,     baseY - amp - 3, (amp + 3) * 2 + 6, COLOR_BG);
    tft.drawFastVLine(x + 1, baseY - amp - 3, (amp + 3) * 2 + 6, COLOR_BG);
    delay(4);
  }
}

// -------------------------------------------------------
// PANTALLA TÍTULO CON ANIMACIÓN COMPLETA
// -------------------------------------------------------
void showTitle() {
  tft.fillScreen(COLOR_BG);

  int W  = tft.width();   // 320
  int cx = W / 2;         // 160

  // Posiciones verticales
  const int textEcgY   = 18;   // "ECG" pequeño
  const int textTitleY = 42;   // "Beat Monitor" grande
  const int qrsBaseY   = 165;  // baseline de la onda (parte baja)
  const int qrsTotalW  = 280;  // ancho de la onda
  const int qrsStartX  = cx - qrsTotalW / 2;  // = 20
  const int qrsAmp     = 50;   // máximo ±px de la onda

  // --- Línea base punteada ---
  for (int x = qrsStartX; x <= qrsStartX + qrsTotalW; x += 5) {
    tft.drawPixel(x, qrsBaseY, COLOR_DARKGRAY);
    delay(3);
  }

  // --- "ECG" typewriter ---
  const char* sub1  = "ECG";
  int         sub1X = typewriterWrite(sub1, cx, textEcgY, 2, COLOR_CYAN, 110);
  delay(150);

  // --- "Beat Monitor" typewriter ---
  const char* title  = "Beat Monitor";
  int         titleX = typewriterWrite(title, cx, textTitleY, 4, COLOR_PINK, 70);
  delay(250);

  // --- Primera onda QRS animada ---
  drawQRS(qrsBaseY, qrsTotalW, qrsStartX, COLOR_GREEN, 16);
  delay(350);

  // --- Segunda onda (late de nuevo, más rápida) ---
  eraseQRS(qrsBaseY, qrsTotalW, qrsStartX, qrsAmp);
  // Restaurar línea base
  for (int x = qrsStartX; x <= qrsStartX + qrsTotalW; x += 5) {
    tft.drawPixel(x, qrsBaseY, COLOR_DARKGRAY);
  }
  delay(100);
  drawQRS(qrsBaseY, qrsTotalW, qrsStartX, COLOR_GREEN, 10);
  delay(900);

  // --- Parpadeo del título antes de borrar ---
  for (int b = 0; b < 3; b++) {
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(COLOR_BG, COLOR_BG);
    tft.drawString("Beat Monitor", titleX, textTitleY, 4);
    delay(120);
    tft.setTextColor(COLOR_PINK, COLOR_BG);
    tft.drawString("Beat Monitor", titleX, textTitleY, 4);
    delay(120);
  }
  delay(150);

  // --- Borrado en orden inverso ---
  eraseQRS(qrsBaseY, qrsTotalW, qrsStartX, qrsAmp);
  delay(60);

  typewriterErase(title, titleX, textTitleY, 4, 45);
  delay(60);

  typewriterErase(sub1, sub1X, textEcgY, 2, 65);

  tft.fillScreen(COLOR_BG);
  delay(100);

  // --- Flash de transición hacia UI ---
  for (int i = 0; i < 3; i++) {
    tft.fillScreen(COLOR_DARKGRAY);
    delay(50);
    tft.fillScreen(COLOR_BG);
    delay(70);
  }
  delay(50);
}

// -------------------------------------------------------
// UI: DIBUJAR INTERFAZ BASE
// -------------------------------------------------------
void drawUI() {
  tft.fillScreen(COLOR_BG);
  tft.drawRect(GRAPH_X - 1, GRAPH_Y - 1, GRAPH_W + 2, GRAPH_H + 2, COLOR_GRAY);
  tft.drawFastHLine(GRAPH_X, GRAPH_MID, GRAPH_W, COLOR_DARKGRAY);
  tft.drawFastHLine(0, PANEL_Y - 6, tft.width(), COLOR_GRAY);

  int col = tft.width() / 4;
  tft.setTextDatum(TC_DATUM);
  tft.setTextColor(COLOR_GRAY, COLOR_BG);
  tft.drawString("BPM",    col * 0 + col / 2, PANEL_Y, 1);
  tft.drawString("AMP",    col * 1 + col / 2, PANEL_Y, 1);
  tft.drawString("ESTADO", col * 2 + col / 2, PANEL_Y, 1);
  tft.drawString("TIEMPO", col * 3 + col / 2, PANEL_Y, 1);

  tft.drawFastVLine(col * 1, PANEL_Y - 6, tft.height(), COLOR_DARKGRAY);
  tft.drawFastVLine(col * 2, PANEL_Y - 6, tft.height(), COLOR_DARKGRAY);
  tft.drawFastVLine(col * 3, PANEL_Y - 6, tft.height(), COLOR_DARKGRAY);
}

// -------------------------------------------------------
// UI: AVISO ELECTRODO DESCONECTADO
// -------------------------------------------------------
void drawElectrodeWarning() {
  tft.fillRect(GRAPH_X, GRAPH_Y, GRAPH_W, GRAPH_H, COLOR_BG);
  tft.setTextDatum(MC_DATUM);
  tft.setTextColor(COLOR_RED, COLOR_BG);
  tft.drawString("ELECTRODO",    GRAPH_X + GRAPH_W / 2, GRAPH_MID - 10, 2);
  tft.drawString("DESCONECTADO", GRAPH_X + GRAPH_W / 2, GRAPH_MID + 10, 2);
}

// -------------------------------------------------------
// UI: ACTUALIZAR PANEL INFERIOR
// -------------------------------------------------------
void updatePanel() {
  int col  = tft.width() / 4;
  int valY = PANEL_Y + 14;

  // BPM
  tft.fillRect(0, valY - 2, col - 1, 36, COLOR_BG);
  tft.setTextDatum(TC_DATUM);
  if (bpm > 0) {
    tft.setTextColor(COLOR_PINK, COLOR_BG);
    tft.drawString(String(bpm), col * 0 + col / 2, valY, 4);
  } else {
    tft.setTextColor(COLOR_GRAY, COLOR_BG);
    tft.drawString("--", col * 0 + col / 2, valY, 4);
  }

  // Amplitud
  tft.fillRect(col + 1, valY - 2, col - 2, 36, COLOR_BG);
  tft.setTextColor(COLOR_YELLOW, COLOR_BG);
  tft.drawString(String(amplitude), col * 1 + col / 2, valY, 4);

  // Estado
  tft.fillRect(col * 2 + 1, valY - 2, col - 2, 36, COLOR_BG);
  tft.setTextColor(estadoColor, COLOR_BG);
  tft.drawString(estado, col * 2 + col / 2, valY, 2);

  // Cronómetro
  unsigned long elapsed = (millis() - startTime) / 1000;
  char timeBuf[10];
  sprintf(timeBuf, "%02d:%02d", (int)(elapsed / 60), (int)(elapsed % 60));
  tft.fillRect(col * 3 + 1, valY - 2, col - 2, 36, COLOR_BG);
  tft.setTextColor(COLOR_WHITE, COLOR_BG);
  tft.drawString(timeBuf, col * 3 + col / 2, valY, 4);
}

// -------------------------------------------------------
// ECG: ACTUALIZAR GRÁFICA (scroll)
// -------------------------------------------------------
void updateGraph(int raw) {
  int y = map(raw, 0, 4095, GRAPH_Y + GRAPH_H - 2, GRAPH_Y + 2);

  int nextIndex = (graphIndex + 3) % GRAPH_W;
  tft.drawFastVLine(GRAPH_X + nextIndex, GRAPH_Y, GRAPH_H, COLOR_BG);
  tft.drawPixel(GRAPH_X + nextIndex, GRAPH_MID, COLOR_DARKGRAY);

  int x = GRAPH_X + graphIndex;
  tft.drawLine(x - 1 < GRAPH_X ? GRAPH_X : x - 1, prevY, x, y, COLOR_GREEN);

  prevY      = y;
  graphIndex = (graphIndex + 1) % GRAPH_W;
}

// -------------------------------------------------------
// WiFi: Enviar datos por HTTP POST
// -------------------------------------------------------
void enviarDatosWiFi(int bpm, int amp, int raw, String estado) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    String json = "{\"bpm\":" + String(bpm) +
                  ",\"amp\":" + String(amp) +
                  ",\"estado\":\"" + estado +
                  "\",\"raw\":" + String(raw) + "}";
    int httpResponseCode = http.POST(json);
    http.end();
    // Puedes imprimir el código de respuesta si quieres debug:
    // Serial.println("HTTP Response code: " + String(httpResponseCode));
  }
}

// -------------------------------------------------------
// ECG: DETECTAR BPM
// -------------------------------------------------------
void detectBPM(int raw) {
  unsigned long now = millis();

  if (!rising && raw > BPM_THRESHOLD && lastSample <= BPM_THRESHOLD) {
    rising = true;
    if (lastBeatTime > 0) {
      unsigned long interval = now - lastBeatTime;
      if (interval > BPM_MIN_INTERVAL) {
        bpm = 60000 / interval;

        if (bpm < 50 || bpm > 120) {
          estado      = "Alerta";
          estadoColor = COLOR_RED;
        } else {
          estado      = "Normal";
          estadoColor = COLOR_GREEN;
        }

        Serial.printf("BPM:%d,AMP:%d,RAW:%d,EST:%s\n",
                      bpm, amplitude, raw, estado.c_str());
        enviarDatosWiFi(bpm, amplitude, raw, estado); // <--- ENVÍO WIFI
      }
    }
    lastBeatTime = now;
  }
  if (raw < BPM_THRESHOLD) rising = false;
  lastSample = raw;
}

// -------------------------------------------------------
// ECG: DETECTAR AMPLITUD
// -------------------------------------------------------
void detectAmplitude(int raw) {
  if (raw < sigMin) sigMin = raw;
  if (raw > sigMax) sigMax = raw;

  static unsigned long lastReset = 0;
  if (millis() - lastReset > 3000) {
    amplitude = sigMax - sigMin;
    sigMin     = 4095;
    sigMax     = 0;
    lastReset  = millis();
  }
}

// -------------------------------------------------------
// SETUP
// -------------------------------------------------------
void setup() {
  Serial.begin(115200);
  pinMode(LO_PLUS,  INPUT);
  pinMode(LO_MINUS, INPUT);

  tft.init();
  tft.setRotation(1);

  showTitle();
  drawUI();

  // --- WiFi ---
  WiFi.begin(ssid, password);
  Serial.print("Conectando a WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado. IP: " + WiFi.localIP().toString());

  startTime = millis();
}

// -------------------------------------------------------
// LOOP
// -------------------------------------------------------
unsigned long lastPanelUpdate = 0;

void loop() {
  bool loPlus  = digitalRead(LO_PLUS);
  bool loMinus = digitalRead(LO_MINUS);

  if (loPlus || loMinus) {
    if (electrodeOk) {
      electrodeOk = false;
      drawElectrodeWarning();
      bpm         = 0;
      estado      = "Alerta";
      estadoColor = COLOR_RED;
      Serial.println("BPM:0,AMP:0,RAW:0,EST:Electrodo desconectado");
      enviarDatosWiFi(0, 0, 0, "Electrodo desconectado"); // <--- ENVÍO WIFI
    }
  } else {
    if (!electrodeOk) {
      electrodeOk = true;
      tft.fillRect(GRAPH_X, GRAPH_Y, GRAPH_W, GRAPH_H, COLOR_BG);
      tft.drawFastHLine(GRAPH_X, GRAPH_MID, GRAPH_W, COLOR_DARKGRAY);
      graphIndex = 0;
      prevY      = GRAPH_MID;
    }

    int raw = analogRead(ECG_PIN);
    detectAmplitude(raw);
    detectBPM(raw);
    updateGraph(raw);

    Serial.printf("RAW:%d\n", raw);
    // Si quieres enviar cada RAW, puedes descomentar:
    // enviarDatosWiFi(bpm, amplitude, raw, estado);
  }

  if (millis() - lastPanelUpdate > 500) {
    updatePanel();
    lastPanelUpdate = millis();
  }

  delay(8);
}