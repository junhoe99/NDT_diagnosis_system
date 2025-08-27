# 🌐Ion-Battery NDT Diagnosis System 

## 🔍 Project Overview

> 이 프로젝트는 초음파를 활용한 **비파괴 검사(NDT) 진단 시스템**입니다. FPGA 기반 하드웨어 제어, 실시간 신호 처리, 그리고 머신러닝을 결합하여 이온 배터리의 SoH(State of Health)대한 자동화된 평가를 수행합니다.


## 🎛️ 핵심 설계 기여 : Custom Pulser System
저는 본 프로젝트에서 **Verilog HDL을 사용하여 설계한 디지털 펄스 생성 시스템**의 구현을 담당했습니다:

- **FSM Design**: 안정적인 펄스 시퀀싱을 위한 FSM 구현
   (drawio FSM chart 그림 첨부) 
- **Programmable Pulse Generation**: 사용자 정의 스펙에 따른 정밀 펄스 생성
  - **Flexible Pulse Shaping**: PWS, POS, NEG 신호를 통한 정밀한 펄스 형태 제어   
    - **PWS (Pulse Width Selection)**: 펄스 폭 제어 신호
    - **POS/NEG Control**: 양극/음극 펄스 제어 (POS0/1, NEG0/1)
- **Burst Count Control**: 프로그래머블 버스트 카운트 설정

## 🏗️ System Architecture

### 1. Hardware Components
- **FPGA Board**: Opal Kelly XEM7320 (Xilinx Artix-7 기반)
- **ADC Module**: SYZYGY ADC (LTC2264-12, 12-bit, 125 MSPS)
- **Custom Pulser Board**: Verilog HDL로 설계한 사용자 정의 펄스 생성 시스템
- **Ultrasonic Transducers**: 다채널 초음파 센싱 시스템
- **Arduino Controller**: 자동화 스캐닝 메커니즘 제어
- **DAC Module**: 신호 생성 및 펄스 제어

### 2. Software Components
- **FPGA Gateware**: Verilog 기반 하드웨어 제어 및 데이터 수집
- **Python GUI Application**: PyQt5 기반 사용자 인터페이스
- **Signal Processing**: 실시간 필터링, FFT 분석, 데이터 시각화
- **Machine Learning Module**: TensorFlow/Keras 기반 CNN 진단 모델

## 🚀 Key Features




### 📡 Data Acquisition
- **High-Speed Sampling**: 최대 125 MSPS 데이터 수집
- **Multi-Channel Support**: 동시 다채널 데이터 수집
- **Configurable FIFO**: 조정 가능한 버퍼 크기 (기본값: 2044 샘플)
- **Real-time Visualization**: 실시간 신호 플롯팅 및 분석

### 🔬 Signal Processing
- **Bandpass Filtering**: 4-7 MHz 주파수 대역 필터링
- **FFT Analysis**: 주파수 도메인 신호 분석
- **DC Removal**: 고급 신호 조건화 알고리즘
- **Decimation**: 분석을 위한 구성 가능한 다운샘플링

### 🤖 Automated Scanning
- ** 2D Grid Scanning**: 프로그래머블 X-Y 축 스캐닝 패턴
- ** Arduino Integration**: 위치 제어를 위한 시리얼 통신
- ** Automated Data Collection**: 각 스캔 포인트별 CSV 파일 생성
- ** Real-time Heatmap Generation**: 강도 매핑 시각화

### 🧠 Machine Learning
- **CNN Architecture**: 패턴 인식을 위한 컨볼루션 신경망
- **SoC/SoH Prediction**: 충전 상태 및 건전성 상태 추정
- **Training Pipeline**: 검증을 포함한 자동화된 모델 훈련
- **Real-time Inference**: 실시간 예측 기능

## 📁 Project Structure

```
NDT_diagnosis_system/
├── 🔧 gateware/                    # FPGA Verilog 코드
│   ├── xem7320_adc.v              # FPGA 최상위 모듈 (Pulser 제어 포함)
│   ├── syzygy-adc-top.v           # ADC 제어 모듈
│   ├── syzygy_dac_spi_module.v    # DAC SPI 인터페이스
│   ├── ip/                        # Xilinx IP 코어(FIFO, IBUFDS
│   ├── oklib/                     # Opal Kelly 라이브러리
│   └── testbench/                 # 시뮬레이션 파일
├── 🐍 python/                      # Python 애플리케이션
│   ├── ULTRAprojectDEMO.py        # 메인 GUI 애플리케이션
│   ├── ULTRAprojectDEMO.ui        # Qt Designer UI 파일
│   ├── ok.py                      # Opal Kelly Python API
│   ├── requirements.txt           # Python 의존성
│   └── datafile/                  # CSV 데이터 저장소
├── vivado_project_bit/         # Vivado 합성 프로젝트
├── vivado_project_sim/         # Vivado 시뮬레이션 프로젝트
└── SZG-ADC-LTC2264-12.gen/    # 생성된 IP 파일
```

## 🛠️ Installation and Setup

### 📋 Prerequisites
- **Hardware**: Opal Kelly XEM7320 FPGA 보드 + SYZYGY ADC 모듈
- **Software**: 
  - Xilinx Vivado (FPGA 개발용)
  - Python 3.7+
  - Arduino IDE (스캐닝 컨트롤러용)
- **Main Python Packages**:
- **PyQt5** (GUI 프레임워크)
- **NumPy, Pandas** (데이터 처리)
- **Matplotlib** (시각화)
- **TensorFlow/Keras** (머신러닝)
- **SciPy** (신호 처리)
- **PySerial** (Arduino 통신)

### 🔧 Hardware Setup
1. **연결**: SYZYGY ADC 모듈을 XEM7320 보드에 연결
2. **Bitfile 로드**: FPGA에 `xem7320_adc.bit` 로드
3. **센서 연결**: ADC 입력에 초음파 트랜스듀서 연결
4. **Arduino 설정**: 스캐닝 제어용 Arduino 설정 (기본값: COM3, 9600 baud)

## 🖥️ Usage

### 📋 Basic Operation Workflow

#### 1. **System Initialization**
   - FPGA bitfile 로드
   - FIFO 크기 및 샘플링 파라미터 구성
   - 버스트 카운트 및 주파수 파라미터 설정

#### 2. **⚙️ Pulser Configuration (핵심 기능)**
   - **펄스 모드 선택**: Transmission/Reflection 모드
   - **PWS 설정**: 펄스 폭 제어
   - **POS/NEG 제어**: 양극/음극 펄스 타이밍
   - **주파수 설정**: 사용자 정의 펄스 주파수

#### 3. **🗺️ Scanning Configuration**
   - X-Y 축 그리드 차원 설정
   - 데이터 파일 저장 디렉토리 선택

#### 4. **📊 Data Acquisition**
   - 자동화된 스캐닝 프로세스 시작
   - 실시간 신호 시각화
   - 스캔 포인트별 자동 CSV 파일 생성

#### 5. **🧠 Data Analysis**
   - 수집된 데이터 훈련용 로드
   - 패턴 인식을 위한 CNN 모델 훈련
   - 실시간 추론 및 진단 수행

### 🎯 Key Parameters
- **FIFO Size**: 2044 샘플 (구성 가능)
- **Sampling Rate**: 시스템 클록에 의해 결정
- **Frequency Range**: 4-7 MHz 밴드패스 필터링
- **Grid Resolution**: 사용자 구성 가능한 X×Y 스캐닝 포인트


## 📊 Data Format

### 📄 CSV Output Structure
각 스캔 포인트는 다음 구조의 CSV 파일을 생성:
- **Column 1**: 시간축 (μs)
- **Column 2**: ADC 읽기값 (전압)
- **Filename**: `adc_data_point_X_Y.csv` (X, Y = 그리드 좌표)

### 🔄 Signal Processing Chain
1. **📡 Raw ADC Data** → 12-bit 부호있는 정수
2. **⚡ Voltage Conversion** → ±1.25V 범위 정규화
3. **🎚️ Bandpass Filtering** → 4-7 MHz 주파수 선택
4. **📊 FFT Analysis** → 주파수 도메인 표현
5. **🌈 Intensity Mapping** → 2D 시각화 데이터

## 🔧 Configuration

### ⚙️ FPGA Parameters
- **⏰ Clock Frequency**: 125 MHz (시스템 클록 기반)
- **📊 ADC Resolution**: 12-bit
- **💾 Sample Buffer**: 구성 가능한 FIFO 깊이
- **🎯 Trigger Mode**: 소프트웨어 제어 수집

### 🔌 Arduino Communication
- **📡 Serial Port**: COM3 (구성 가능)
- **⚡ Baud Rate**: 9600
- **📝 Protocol**: 단순 ASCII 명령 인터페이스

### 🎛️ Pulser System Configuration (핵심 설계)
- **⚡ PWS Control**: 펄스 폭 선택 신호
- **📈 POS/NEG Timing**: 양극/음극 펄스 타이밍 제어
- **🔄 Burst Count**: 프로그래머블 버스트 시퀀스
- **🎯 Mode Selection**: Transmission/Reflection 모드 전환
- **⏱️ Frequency Control**: 200MHz 기준 주파수 분주

## 🚨 Troubleshooting

## 📈 Performance Specifications

- **⚡ Maximum Sampling Rate**: 125 MSPS
- **📊 ADC Resolution**: 12-bit (4096 레벨)
- **🎚️ Frequency Response**: 4-7 MHz 최적화
- **🗺️ Scan Speed**: 데이터 포인트당 ~5ms
- **📊 Data Throughput**: 샘플당 ~16 바이트 (4채널 × 4바이트)

## 🤝 Contributing

---
