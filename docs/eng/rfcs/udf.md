# RFC Universal Data Fabric

```
Network Working Group                                          M. Bodi
Request for Comments: DRAFT                                  March 2025
Category: Informational

             Universal Data Fabric - A Schema-Driven Streaming Substrate

```

## Abstract

This document defines the Universal Data Fabric (UDF), a unified namespace for addressing and streaming all data in a distributed system. The UDF represents a paradigm shift where paths function simultaneously as identifiers and objects, schemas are just another type of stream, and the distinction between types and instances dissolves. By using a hybrid architecture combining HTTP-based registration with streaming data transport, the UDF enables system adaptation without redeployment while maintaining hierarchical permission and validation guarantees.

## 1. Introduction

Traditional approaches to system design fragment data and behavior across disparate components connected by brittle interfaces. Natural language commands cannot be reliably translated into robust robot execution because our systems lack a unified substrate for representing and transforming state.

The Universal Data Fabric (UDF) addresses this challenge by establishing a universal namespace where:

- Every path is a stream that can be published to or subscribed from
- Schemas are paths in the same namespace as the data they describe
- Parent paths control the creation and validation of their children
- All components interact through the same streaming interface

Rather than building ever more complex translations between fragmented components, the UDF provides a unified streaming substrate where natural language can progressively decompose into executable actions through schema-driven validation.

## 2. Core Principles

### 2.1. Universal Live Paths

Every path in the UDF is immediately accessible as a stream without deployment steps. The path exists by virtue of its registration in the namespace:

```
# Register a new path
POST /registration/robot/arm/position

# Stream values to and from this path
PUBLISH robot/arm/position 45.2
SUBSCRIBE robot/arm/position

```

All paths are accessible through the same streaming interface regardless of implementation details. No servers need to be "spun up" for paths to become available.

### 2.2. Path-Object Duality

A path simultaneously functions as both an identifier and the object it represents. The structure of an object directly maps to its subpath hierarchy:

```
Object notation: robot.arm.joint[1].position
Path notation:   /robot/arm/joint/1/position

```

Subscribing to a path returns the object at that location:

```
SUBSCRIBE /robot/arm → {"joint": {"1": {"position": 45.2}}}
SUBSCRIBE /robot/arm/joint/1 → {"position": 45.2}

```

### 2.3. Self-Describing Schemas

Every object's schema exists as another path in the namespace:

```
Object path: /robot/arm/joint/1
Schema path: /robot/arm/joint/1/schema

```

Schemas are regular streams, accessed through the same operations as any data. Parent nodes control the schemas of their children, enforcing validation hierarchically.

### 2.4. Unified Reference Mechanism

References use the standard JSON Schema $ref mechanism for both schemas and instances:

```json
{
  "$ref": "/path/to/target"
}

```

Since $ref can point to constantly updated values (effectively "live" constants), this single mechanism handles both schema references and instance references, simplifying the conceptual model.

### 2.5. Type-Instance Unity

Types and instances exist on a spectrum of constraint. An instance is simply a fully constrained type (a singleton with exactly one valid value):

```
# A type: partially constrained state space
PUBLISH /types/temperature/schema {
  "type": "number",
  "minimum": 0,
  "maximum": 100
}

# An instance: fully constrained state space
PUBLISH /sensors/temperature 23.5

```

This unification enables consistent validation mechanics across the system.

## 3. Architecture

The UDF uses a hybrid architecture combining:

1. **Registration Service** (FastAPI) - Handles path registration, permission checks, and schema validation
2. **Streaming Transport** (Zenoh) - Manages the real-time data flow between components

This approach leverages HTTP for control operations and an efficient streaming protocol for data transport.

```
                +------------------+
Registration    |                  |
------------->  |  FastAPI Service |
                |                  |
                +------------------+
                        |
                        | Register paths,
                        | schemas, permissions
                        v
                +------------------+
                |                  |
                |  Zenoh Streaming |
                |                  |
                +------------------+
                        ^
                        | PUBLISH/SUBSCRIBE
                        |
                +------------------+
                |                  |
Components      |     UDF Clients  |
                |                  |
                +------------------+

```

### 3.1. Path Registration

Before streaming to a path, it must be registered:

```
POST /register/path
{
  "path": "/robot/arm/position",
  "schema": { "type": "number" },
  "permissions": ["robot_control_service"]
}

```

Registration validates:

1. The parent path exists
2. The requester has permission to create under the parent
3. The schema is valid and compatible with parent constraints

### 3.2. Permission Model

The UDF uses a hierarchical permission model:

1. Each universe (top-level namespace) belongs to an account
2. Each path has a list of authorized writers
3. A path can only be created with permission from its parent
4. Child schemas must be compatible with parent schemas

This resembles a filesystem where directories control who can create files within them.

## 4. Data Model

### 4.1. Streaming Document Structure

All data in the UDF is represented as streams of documents with these core types:

- Primitive values (strings, numbers, booleans, null)
- Objects (collections of key-value pairs)
- Arrays (ordered lists of values)
- References (using $ref to other paths)

### 4.2. Path Interpretation Rules

| Path Syntax | Interpretation |
| --- | --- |
| /a/b/c | Member c of object b, itself member of a |
| /a/b/2/ | Third element (index 2) of array b, member of a |
| /a/b/$ref/other | Member b references /other |
| /a/b = 5 | Assignment: b is set to 5 |

### 4.3. Path Resolution Process

When a path is accessed, the resolution sequence is:

1. Check if the path exists in the registry
2. If it contains references, resolve them
3. Apply any transformations defined by schemas
4. Return the resulting stream

## 5. Node Interaction Model

Active entities (nodes) in the UDF interact through a consistent pattern:

```
                 +----------------+
                 |                |
   observation   |                |    action
   ----------->  |      NODE      | ----------->
                 |                |
                 |                |
                 +----------------+

```

Each node has:

- An observation path for inputs
- An action path for outputs

### 5.1. Agent Implementation

Agents can be implemented using Python generators, which provide a natural way to process streams:

```python
from mbodios.types.sample import Sample

class Agent(BaseAgent[ObservationT,ActionT,StateT, RewardT]):
   def act(obs: ObservationT) -> ActionT:
      # Implement
   

class World(Sample):
   objects = StreamedField(

      

```

This pattern creates a clean, synchronous-looking flow while handling asynchronous streaming.

### 5.2. External System Integration

External systems are integrated via specialized actors:

```
                   +----------------+
                   |                |
External System    |                |
---------------->  |  Bridge Actor  |  -----------> UDF Paths
                   |                |
                   |                |
                   +----------------+

```

These actors:

1. Connect to external APIs/systems
2. Translate external data to UDF paths
3. Publish/subscribe to appropriate streams
4. Map UDF operations to external system calls

## 6. Operations

### 6.1. Basic Operations

The UDF provides these core operations:

- PUBLISH - Send data to a path
- SUBSCRIBE - Receive data from a path
- REGISTER - Create a new path
- UNREGISTER - Remove a path

Additional operations include:

- PUT/PATCH - Request current value of a path
- SUBSCRIBE - Subscribe to changes at a path
- PUBLISH - Publish to a path.

### 6.2. Example Flow

```
# Registration phase
POST /register/path { "path": "/sensors/temperature", ... }
POST /register/path { "path": "/alerts/temperature", ... }

# Runtime phase
PUBLISH /sensors/temperature 75.5
# Agent processes this value
SUBSCRIBE /alerts/temperature → {"level": "normal", "value": 75.5}

PUBLISH /sensors/temperature 95.8
# Agent updates its output based on threshold
SUBSCRIBE /alerts/temperature → {"level": "warning", "value": 95.8}

```

## 7. Schema Validation and Evolution

### 7.1. Schema Location and Format

Schemas use JSON Schema format and exist at predictable paths:

```
Object: /robot/arm/joint/1
Schema: /robot/arm/joint/1/schema

```

### 7.2. Schema Evolution

When schemas change, the system:

1. Validates the new schema against parent constraints
2. Updates the schema path with the new definition
3. Future data published to affected paths must conform to the new schema

Schema evolution happens through the same streaming mechanism as any other data:

```
PUBLISH /robot/arm/joint/1/schema {
  "type": "object",
  "properties": {
    "position": {
      "type": "number",
      "minimum": 0,
      "maximum": 90
    },
    "velocity": {
      "type": "number",
      "default": 0
    }
  },
  "required": ["position"]
}

```

## 8. Performance Considerations

The UDF architecture has several performance advantages:

1. **Path Locality**: The hierarchical structure creates natural data locality that can be exploited for caching
2. **Stream Efficiency**: Modern streaming protocols like Zenoh are highly optimized for real-time data
3. **Partial Subscriptions**: Clients can subscribe to exactly the paths they need
4. **Hierarchical Caching**: Caches can be organized to mirror the path hierarchy

With appropriate caching, this approach can be more efficient than traditional architectures that require complex translations between components.

## 9. Security Considerations

The UDF requires robust security measures:

1. **Authentication**: All registration operations must be authenticated
2. **Authorization**: Path permissions must be strictly enforced
3. **Transport Security**: All communications should be encrypted
4. **Isolation**: Each universe (account) must be fully isolated

## 10. Example Use Cases

### 10.1. Robotic Control

```
# Schema definition
PUBLISH /robot/arm/schema {
  "type": "object",
  "properties": {
    "position": { "type": "array", "items": { "type": "number" } },
    "velocity": { "type": "array", "items": { "type": "number" } }
  }
}

# Current state reporting
PUBLISH /robot/arm/position [1.2, 0.5, 0.3]

# Command issuance
PUBLISH /robot/arm/target [1.5, 0.7, 0.3]

# Status updates as motion occurs
PUBLISH /robot/arm/position [1.3, 0.55, 0.3]
PUBLISH /robot/arm/position [1.4, 0.6, 0.3]
PUBLISH /robot/arm/position [1.5, 0.7, 0.3]

```

### 10.2. Natural Language Processing

```
# Human instruction ingestion
PUBLISH /nlp/input "Pick up the red cube and place it on the blue platform"

# Progressive decomposition
PUBLISH /nlp/parsed {
  "action": "sequence",
  "steps": [
    {
      "action": "pick",
      "object": { "type": "cube", "color": "red" }
    },
    {
      "action": "place",
      "destination": { "type": "platform", "color": "blue" }
    }
  ]
}

# Object resolution
PUBLISH /perception/objects/cube_7 {
  "type": "cube",
  "color": "red",
  "position": [0.5, 0.3, 0.1]
}

# Task execution
PUBLISH /tasks/current {
  "action": "pick",
  "object": { "$ref": "/perception/objects/cube_7" }
}

```

## 11. Implementation Recommendations

A complete UDF implementation requires:

1. FastAPI service for registration and validation
2. Zenoh for efficient real-time streaming
3. Python client library with generator support
4. Schema validation engine
5. Permission enforcement system

## 12. Conclusion

The Universal Data Fabric provides a unified streaming substrate for building adaptable systems. By representing all system aspects as streams in a hierarchical namespace, UDF enables dynamic adaptation without redeployment while maintaining schema validation and permission guarantees.

This approach is particularly valuable for robotic systems that must translate natural language instructions into physical actions in uncertain environments. The UDF creates a foundation where tasks can be progressively decomposed through schema-driven validation, bridging the gap between human intent and robotic execution.

## References

1. JSON Schema: A Media Type for Describing JSON Documents
https://json-schema.org/draft/2020-12/json-schema-core.html
2. Zenoh: Zero Overhead Pub/sub, Store/query and Compute
https://zenoh.io/
3. FastAPI: A modern, fast web framework for building APIs
https://fastapi.tiangolo.com/
4. Python Generators: Simplified, Generator-Based Coroutines
https://peps.python.org/pep-0342/

# Comparison to Existing Approaches and Problems Solved by UDF

## 1. Comparison to Existing Approaches

### 1.1 ROS (Robot Operating System)

**Key Differences:**

- **ROS** uses a topic-based publish/subscribe system with static message types defined at compile time
- **UDF** provides a hierarchical namespace where all data exists as streams with schemas that can evolve at runtime

**Fundamental Limitations of ROS:**

- Message types cannot evolve without recompilation and redeployment
- No hierarchical organization or permission model
- No built-in schema validation
- Components must be explicitly launched and configured
- No unified mechanism for progressive task decomposition

ROS requires substantial engineering effort to adapt to new requirements or environments, while UDF allows for runtime evolution through schema updates and dynamic references.

### 1.2 Traditional Microservice Architectures

**Key Differences:**

- **Microservices** communicate via explicit API contracts requiring custom integration code
- **UDF** uses a universal namespace where services interact through shared paths without custom integration

**Fundamental Limitations of Microservices:**

- Every service pair requires custom integration code
- API versioning creates significant maintenance overhead
- No unified state representation
- Service boundaries create artificial barriers to data access
- Complex service discovery mechanisms needed

While microservices offer isolation, they fragment the system state across multiple boundaries, making system-wide reasoning and adaptation difficult. UDF provides a unified state representation while maintaining isolation through permissions.

### 1.3 Event-Driven Architectures

**Key Differences:**

- **Event-Driven Architectures** use unstructured or weakly-typed events with ad-hoc subscribers
- **UDF** provides a structured namespace with schema validation and hierarchical permissions

**Fundamental Limitations of Event-Driven Architectures:**

- Event schemas are often implicit or weakly enforced
- No centralized registry of event types
- No hierarchical organization of event streams
- Complex event processing requires custom code
- No built-in permission model

Event-driven architectures share UDF's streaming nature but lack its structured namespace, schema validation, and permission model. UDF brings order to the chaos of event streams while preserving their real-time nature.

### 1.4 Digital Twin Approaches

**Key Differences:**

- **Digital Twins** typically use custom data models with synchronization to physical assets
- **UDF** provides a unified namespace where digital representations exist alongside control interfaces

**Fundamental Limitations of Digital Twins:**

- Often use proprietary data models
- Focus on representation rather than action
- Limited support for progressive task decomposition
- Typically require custom integration with control systems
- No unified programming model

Digital twins excel at representing physical systems but struggle to bridge the gap to control them. UDF unifies representation and control within a single namespace, enabling seamless transitions from perception to action.

### 1.5 Traditional Database Systems

**Key Differences:**

- **Databases** store data in tables or documents with queries for access
- **UDF** represents all data as streams in a hierarchical namespace

**Fundamental Limitations of Databases:**

- CRUD operations rather than streaming
- Schema changes are difficult and often require migrations
- No built-in mechanism for real-time updates
- Focus on storage rather than communication
- No unified model for code and data

Databases excel at persistent storage but struggle with real-time interaction and schema evolution. UDF treats persistence as just another aspect of a unified streaming model, allowing for seamless transitions between stored and live data.

### 1.6 Semantic Web and Linked Data

**Key Differences:**

- **Semantic Web** focuses on description and inference using RDF and OWL
- **UDF** provides a practical streaming infrastructure with schema validation

**Fundamental Limitations of Semantic Web:**

- Focus on description rather than action
- Complex ontologies with steep learning curves
- Limited support for real-time data
- Inference engines are often slow for real-time use
- No built-in streaming or permission model

The Semantic Web offers rich descriptive capabilities but lacks the practical infrastructure for real-time systems. UDF provides a pragmatic approach to linking data while maintaining performance and security.

### 1.7 Actor Model Systems (KAFKA, Orleans)

**Key Differences:**

- **Actor Model** uses message passing between isolated actors with encapsulated state
- **UDF** exposes all state in a unified namespace with streaming access

**Fundamental Limitations of Actor Model:**

- State is encapsulated and not directly accessible
- No unified namespace for addressing all system components
- No built-in schema validation
- Message types are typically static
- No hierarchical organization or permission model

Actor systems excel at isolation and fault tolerance but struggle with system-wide reasoning and adaptation. UDF provides a unified view of the system while maintaining isolation through permissions.

## 2. Problems Solved

### 2.1 The Decomposition Problem in Dynamic Environments

**Problem:**
Traditional task planning assumes tasks can be statically decomposed into a fixed hierarchy of subtasks. This breaks down in dynamic environments where:

- The appropriate decomposition depends on runtime context
- Subtasks may need to be reordered or merged opportunistically
- New subtasks may need to be introduced based on sensor data
- Success conditions may need to be refined as execution proceeds

**Why Traditional Approaches Fail:**

- Fixed task hierarchies cannot adapt to unexpected situations
- Replanning requires expensive computation from scratch
- No mechanism for partial decomposition that completes at runtime
- Brittle interfaces between planning and execution layers

**How UDF Solves This:**

1. **Schema-Driven Validation**: Tasks are represented as schemas that can be progressively refined
2. **Streaming Updates**: New information continuously flows through the system
3. **Dynamic References**: Components can be rewired without code changes
4. **Hierarchical Decomposition**: High-level tasks can be progressively broken down as more information becomes available

**Example:**

```
# High-level instruction with partial specification
PUBLISH /tasks/current {
  "action": "retrieve",
  "object": { "type": "cup", "location": "kitchen" }
}

# Progressive refinement as perception provides more information
PUBLISH /tasks/current {
  "action": "retrieve",
  "object": { "$ref": "/perception/objects/cup_3" },
  "subtasks": [
    { "action": "navigate", "destination": [3.2, 1.5, 0.0] },
    { "action": "grasp", "object": { "$ref": "/perception/objects/cup_3" } },
    { "action": "navigate", "destination": [0.0, 0.0, 0.0] }
  ]
}

```

### 2.2 The Schema Evolution Problem

**Problem:**
Systems that run for extended periods inevitably need to evolve their data structures, but traditional approaches require:

- Database migrations
- API version management
- Code updates and redeployment
- Synchronization of updates across components

**Why Traditional Approaches Fail:**

- Schema changes require system-wide coordination
- Backward compatibility becomes increasingly complex
- No unified mechanism for propagating schema changes
- Running code often depends on static type definitions

**How UDF Solves This:**

1. **Schemas as Streams**: Schemas exist in the same namespace as the data they describe
2. **Hierarchical Validation**: Parent schemas control what changes are valid in children
3. **Reference Resolution**: Components refer to schemas by path, automatically getting updates
4. **Runtime Validation**: All data is validated against current schemas at publish time

**Example:**

```
# Original schema
PUBLISH /sensors/temperature/schema { "type": "number" }

# Data conforming to original schema
PUBLISH /sensors/temperature 22.5

# Updated schema with additional metadata
PUBLISH /sensors/temperature/schema {
  "type": "object",
  "properties": {
    "value": { "type": "number" },
    "unit": { "type": "string", "enum": ["C", "F"] },
    "timestamp": { "type": "string", "format": "date-time" }
  },
  "required": ["value"]
}

# Data conforming to new schema
PUBLISH /sensors/temperature {
  "value": 22.5,
  "unit": "C",
  "timestamp": "2025-03-08T10:15:30Z"
}

```

### 2.3 The Integration Challenge

**Problem:**
Modern systems comprise numerous heterogeneous components that must be integrated, leading to:

- Custom adapter code for each component pair
- Brittle point-to-point integrations
- Complex error handling across integration boundaries
- No unified view of system state

**Why Traditional Approaches Fail:**

- Point-to-point integrations scale poorly (O(n²) problem)
- Different components use different data models
- No standard way to discover or access component state
- Integration logic is often duplicated across the system

**How UDF Solves This:**

1. **Universal Namespace**: All components publish to and subscribe from the same namespace
2. **Schema Validation**: Data is automatically validated against schemas
3. **Dynamic References**: Components can be rewired without code changes
4. **Bridge Actors**: Standardized pattern for integrating external systems

**Example:**

```
# Camera system publishes perception data
PUBLISH /perception/camera_1/objects [
  { "id": "cup_3", "type": "cup", "position": [3.2, 1.5, 0.5] }
]

# Planning system subscribes to perception and publishes tasks
SUBSCRIBE /perception/camera_1/objects
PUBLISH /tasks/current { "action": "grasp", "object": { "$ref": "/perception/objects/cup_3" }}

# Robot control subscribes to tasks and publishes actions
SUBSCRIBE /tasks/current
PUBLISH /robot/arm/target [3.2, 1.5, 0.5]

```

In this example, the perception system, planner, and robot controller all interact through the unified namespace without custom integration code.

### 2.4 The Natural Language to Action Gap

**Problem:**
Translating natural language instructions into robotic actions requires bridging semantic understanding and physical control, traditionally requiring:

- Custom translation layers
- Brittle mappings between language and control
- Extensive engineering for each new command
- Limited adaptation to novel situations

**Why Traditional Approaches Fail:**

- Natural language is inherently ambiguous and context-dependent
- Traditional systems use fixed mappings from language to actions
- No mechanism for progressive refinement of instructions
- Limited feedback loop between execution and understanding

**How UDF Solves This:**

1. **Progressive Decomposition**: Instructions can be refined as more context becomes available
2. **Schema Validation**: Each decomposition step is validated against schemas
3. **Streaming Updates**: Real-time feedback flows through the system
4. **Path References**: Language components can directly reference physical entities

**Example:**

```
# Natural language input
PUBLISH /nlp/input "Grab the red cup from the table and bring it to me"

# Initial semantic parsing
PUBLISH /nlp/parsed {
  "action": "sequence",
  "steps": [
    {
      "action": "grasp",
      "object": { "type": "cup", "color": "red", "location": "table" }
    },
    {
      "action": "bring",
      "object": { "$ref": "#/steps/0/object" },
      "destination": "user"
    }
  ]
}

# Progressive refinement as perception provides more information
PUBLISH /tasks/current {
  "action": "grasp",
  "object": { "$ref": "/perception/objects/cup_3" }
}

```

In this example, the natural language instruction is progressively refined into concrete actions as more information becomes available from perception.

### 2.5 The Engineering Overhead Problem

**Problem:**
Traditional systems require extensive engineering effort to:

- Adapt to new requirements
- Handle edge cases
- Integrate new components
- Maintain backward compatibility
- Deploy updates

**Why Traditional Approaches Fail:**

- Code changes require redeployment
- Static typing limits runtime adaptation
- No unified mechanism for discovering system state
- Brittleness in the face of unexpected situations

**How UDF Solves This:**

1. **Schema-Driven Validation**: Behavior is governed by schemas, not code
2. **Dynamic References**: Systems can be rewired without code changes
3. **Universal Namespace**: All components share the same addressing scheme
4. **Streaming Updates**: Changes propagate automatically through the system

**Example:**
Before UDF, adding support for a new sensor might require:

1. Creating new message types
2. Updating interfaces in multiple components
3. Adding new ROS topics or services
4. Recompiling and redeploying code
5. Updating launch files and configuration

With UDF, the same change requires:

1. Registering the new sensor path
2. Publishing its schema
3. Components that need the data simply subscribe to its path

### 2.6 The Formal Verification Challenge

**Problem:**
Safety-critical systems require formal verification, but traditional approaches struggle with:

- Verifying distributed systems
- Reasoning about dynamic reconfiguration
- Tracking data dependencies across components
- Verifying compliance with safety constraints

**Why Traditional Approaches Fail:**

- No unified model for system state
- Complex interactions between components
- Verification separate from implementation
- Static analysis struggles with dynamic behavior

**How UDF Solves This:**

1. **Schema as Contract**: Schemas provide formal specifications for all data
2. **Path Dependencies**: References explicitly show data dependencies
3. **Runtime Validation**: All data is validated against schemas
4. **Unified Namespace**: System-wide reasoning becomes possible

**Example:**

```
# Safety constraint encoded in schema
PUBLISH /robot/arm/schema {
  "type": "object",
  "properties": {
    "position": {
      "type": "array",
      "items": { "type": "number" },
      "minItems": 3,
      "maxItems": 3
    },
    "velocity": {
      "type": "array",
      "items": { "type": "number" },
      "minItems": 3,
      "maxItems": 3
    }
  },
  "allOf": [
    {
      "if": {
        "properties": {
          "position": {
            "items": {
              "0": { "minimum": 0, "maximum": 0.3 }
            }
          }
        }
      },
      "then": {
        "properties": {
          "velocity": {
            "items": {
              "0": { "minimum": -0.1, "maximum": 0.1 }
            }
          }
        }
      }
    }
  ]
}

```

This schema formally encodes a safety constraint: when the arm is close to the robot body (x < 0.3), its velocity in that direction must be limited to prevent self-collision.

##