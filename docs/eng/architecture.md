# Architecture

## Overview

The Mbodi architecture is a hybrid system that combines symbolic planning with learned policies. It is designed to be robust and reliable in everyday environments.

## Components

```mermaid
graph TD
    subgraph "Robot Device"
        A[Microphone] -->|Raw Audio| B[Audio Preprocessor]
        V[Camera] -->|Raw Video| W[Video Preprocessor]
        B -->|Audio Chunks| C[Zenoh Client]
        W -->|Video Frames| C
        D[Other Sensors] -->|Sensor Data| C
        C -->|TTS Audio| K[Text-to-Speech]
        K -->|Audio Output| L[Speaker]
    end

    subgraph "Cloud Infrastructure"
        C -->|Audio/Video Stream| E[Zenoh Server]
        E -->|Audio Chunks| F[Audio Buffer]
        E -->|Video Frames| X[Video Buffer]
        F -->|Buffered Audio| G[Streaming Whisper Processor]
        X -->|Buffered Video| Y[Pose Estimator]
        G -->|Transcriptions| H[Transcription Validator]
        Y -->|Pose Estimates| Z[Pose Validator]
        H -->|Validated Transcriptions| I[LLM Processor]
        Z -->|Validated Poses| P[Action Planner]
        I -->|LLM Output| J[Output Splitter]
        J -->|Speech Output| O1[Speech Validator]
        J -->|Action Output| O2[Action Validator]
        O1 -->|Validated Speech| S1[Speech State]
        O2 -->|Validated Actions| S2[Action State]
        P -->|Planned Actions| S3[World State]
        S1 & S2 & S3 -->|Current States| I
    end

    E -->|TTS Data| C
    E -->|Actions| C
    C -->|Actions| M[Actuators]

    subgraph "States"
        S1 -.->|Influences| S2
        S2 -.->|Influences| S3
        S3 -.->|Influences| S1
    end
```
