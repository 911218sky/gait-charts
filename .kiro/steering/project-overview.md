---
inclusion: always
---

# Gait Charts Dashboard - Project Overview

## Product Description

Gait Charts Dashboard is a comprehensive Flutter-based analytics platform for gait analysis and biomechanical data visualization. The application provides healthcare professionals and researchers with tools to analyze walking patterns, track patient progress, and generate detailed reports.

## Key Features

### Core Analytics
- **Session Management**: Track and organize gait analysis sessions
- **User Profiles**: Comprehensive patient/subject management
- **Cohort Analysis**: Group-based statistical analysis and benchmarking
- **Video Playback**: Synchronized video analysis with data visualization

### Data Visualization
- **Trajectory Playback**: 3D movement visualization
- **Speed Heatmaps**: Velocity distribution analysis
- **Swing Info Heatmaps**: Gait phase analysis
- **Frequency Analysis**: FFT-based periodogram analysis
- **Y-Height Difference**: Vertical movement analysis

### Platform Support
- **Desktop**: Windows, macOS, Linux (primary target)
- **Web**: Browser-based access
- **Mobile**: Android support (secondary)

## Target Users

### Primary Users
- **Healthcare Professionals**: Physiotherapists, orthopedic specialists
- **Researchers**: Biomechanics researchers, gait analysis specialists
- **Clinical Staff**: Medical technicians, data analysts

### Use Cases
- Clinical gait assessment
- Research data analysis
- Patient progress tracking
- Comparative cohort studies
- Report generation for medical records

## Technical Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.x with Dart
- **State Management**: Riverpod 3.x
- **UI Framework**: Material Design 3 with custom dark theme
- **Architecture**: Domain-Driven Design (DDD) with feature-based structure

### Backend Integration
- **API**: RESTful API communication
- **Data Format**: JSON with typed models
- **File Handling**: BAG file processing, video streaming
- **Authentication**: JWT-based admin authentication

### Data Processing
- **Real-time Analysis**: Live trajectory processing
- **Statistical Computing**: Cohort benchmarking, trend analysis
- **File Processing**: BAG file extraction and parsing
- **Video Processing**: Synchronized playback with data overlay

## Business Goals

### Short-term Objectives
- Streamline gait analysis workflow for healthcare professionals
- Provide intuitive data visualization tools
- Enable efficient patient data management
- Support research data analysis needs

### Long-term Vision
- Become the leading platform for gait analysis visualization
- Enable large-scale biomechanical research
- Support AI-powered gait pattern recognition
- Facilitate clinical decision-making through data insights

## Quality Standards

### Performance Requirements
- **Responsiveness**: UI interactions < 100ms
- **Data Loading**: Large datasets < 3 seconds
- **Video Playback**: Smooth 30fps playback
- **Memory Usage**: Efficient handling of large trajectory data

### Reliability Standards
- **Error Handling**: Graceful degradation for network issues
- **Data Integrity**: Robust validation and error recovery
- **Cross-platform**: Consistent behavior across all platforms
- **Accessibility**: WCAG 2.1 AA compliance where applicable

## Development Priorities

1. **User Experience**: Intuitive, responsive interface design
2. **Data Accuracy**: Precise calculations and visualizations
3. **Performance**: Efficient handling of large datasets
4. **Maintainability**: Clean, well-documented codebase
5. **Scalability**: Architecture that supports future growth