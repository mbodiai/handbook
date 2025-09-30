# Overview: VisionSynapse publishes a single `SensorFrame` to state

## Goal

Publish **one atomic object** (`SensorFrame`) that already contains the image+depth pairs for **all cameras**, and write it to the Zenoh-backed state under a **single key**. Consumers read that one key and deserialize back to `SensorFrame`.

## Components

- **VisionSynapse** (producer): owns the loop and writes to state.
- **Sensor backend** : provides a **merged** multi-camera frame.
- **State** (Zenoh-backed): simple key/value store.
- **SensorFrame**: data model that holds all per-camera payloads in one object.

## Data Model

- `SensorFrame` already aggregates per-camera data:  
  `data = { "cam0": {...}, "cam1": {...}, "cam2": {...} }`,  
  where each entry carries **both** image and depth (plus intrinsics/metadata).

## Single State Key

- **Key:** `sensor_frame`  
- **Value:** `bytes` (serialized `SensorFrame`)

## Serialization

- **Producer:**  
  `raw_bytes = SensorFrame.model_dump()` → `zbytes = z_serialize(raw_bytes)`
- **Consumer:**  
  `raw_bytes = z_deserialize(bytes, zbytes)` → `frame = SensorFrame.model_load(raw_bytes)`

> Rationale: Zenoh carries `bytes`; `model_dump/model_load` keep Python-side fidelity.

## Control Flow (Who calls what, when)

1. **Startup**
   - `VisionSynapse.__init__()` selects backend (`zed` or `realsense`) and constructs a sensor via `make_sensor()`.
   - `self._capture = self._sensor.capture` returns a **single, merged** `SensorFrame`.

2. **Run Loop**
   - `VisionSynapse.run()` repeatedly calls `process()`.

3. **Produce one multi-cam frame**
   - `process()` calls `frame = self._capture()` to obtain the **merged** `SensorFrame`.

4. **Serialize & publish**
   - `raw = frame.model_dump()`
   - `zbytes = z_serialize(raw)`
   - `self.state.set("sensor_frame", zbytes)`

5. **Consumer side (any process)**
   - `zbytes = state.get("sensor_frame")`
   - `raw = z_deserialize(bytes, zbytes)`
   - `frame = SensorFrame.model_load(raw)`

## Minimal Producer Pseudocode

```python
def process(self):
    # 1) capture a single, merged multi-cam SensorFrame
    frame: SensorFrame = self._capture()

    # 2) serialize & publish atomically
    raw = frame.model_dump()
    zbytes = z_serialize(raw)
    self.state.set("sensor_frame", zbytes)
```