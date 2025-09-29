# Mbodi AI Technical Strategy

## What We Build

We build robots that work reliably in everyday environments. Success is binary - either the task gets done right, or it doesn't. We're not interested in confidence scores or partial success.

## Our Core Innovation

**Scene Grammar**: A hybrid architecture that combines the reliability of symbolic planning with the adaptability of learned policies. We represent the world as a typed scene graph where:

- **Nodes** = Objects (cup, shelf, robot) with poses and properties
- **Edges** = Relations (on, in, near) with logical semantics
- **Goals** = Logical formulas (on(cup, shelf) ∧ clear(table))

This lets robots compose known skills into novel tasks - if you can grasp and pour, you can pour from cup to bowl, even if never seen before.

## Key Technical Choices

### 1. Verifiable Execution

Every action has preconditions and effects defined as logical predicates. We can prove whether G ⊨ φ (scene satisfies goal) after execution.

### 2. Hybrid Control

- **Reactive layer**: Learned policies for time-critical tasks (grasping, collision avoidance)
- **Deliberative layer**: Symbolic planning for complex multi-step tasks
- **Safety shield**: Real-time constraint enforcement that can override unsafe actions

### 3. Unified World Model

Single source of truth: typed scene graph with uncertainty tracking and coordinate frame management. Everything - perception, planning, control - operates on this model.

## Strengths of the Scene Grammar

### Compositional Intelligence

Traditional AI memorizes task sequences. We compose skills logically. If you know "grasp" and "pour", you can figure out "pour from cup to bowl" without training.

### Safety by Design

Every action is defined by logical preconditions and effects. We can mathematically verify success and explain failures in human terms.

### Unified World Model

One scene graph serves perception, planning, and control. No translation layers, no conflicting representations.

### Hybrid Performance

Reactive policies handle fast, routine tasks. Deliberative planning handles complex, novel situations. Both use the same world model.

## Technical Implementation

### Scene Graph Architecture

**Nodes**: Objects with unique IDs, types, and properties (pose, color, material)
**Edges**: Typed relations (on, in, near, connected_to) with logical semantics
**Frames**: Coordinate hierarchy ensuring every pose has a clear world reference

**Key Innovation**: Predicates computed from graph structure, not stored separately. This ensures consistency and enables logical reasoning.

### Language Processing

Natural language instructions parse to logical goals + skill lookups:

```python
"Stack red cup on shelf" → on(red_cup, shelf) ∧ clear(table)
+ retrieve stacking skills from knowledge base
```

### Planning & Control

- **TAMP**: Task-motion planning with continuous geometric constraints
- **Behavior Trees**: Reactive execution with fallback policies
- **Safety Shield**: Real-time QP-based constraint enforcement
- **Retrieval**: Prior trajectories bias planning under latency budgets

## Roadmap

### Phase 1: Core Infrastructure (Now)

- Scene graph with uncertainty tracking
- Basic TAMP with geometric constraints
- Safety shield with QP-based enforcement
- Monitoring and debugging tools

### Phase 2: Learning Integration (Next 6 months)

- Diffusion policies under safety shield
- Retrieval-augmented planning
- Automated data collection
- Performance benchmarking

### Phase 3: Autonomous Operation (Next Year)

- Skill acquisition from demonstration
- Multi-robot coordination
- Production deployment with reliability SLAs

## Key References

- Kaelbling, L. P., & Lozano‑Pérez, T. (2011). Hierarchical task and motion planning in the now
- Chi, C., et al. (2023). Diffusion Policy: Visuomotor Policy Learning via Action Diffusion
- Dalal, G., et al. (2018). Safe Exploration in Continuous Action Spaces
