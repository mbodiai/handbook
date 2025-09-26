# Mbodi AI Technical Strategy

## Executive Summary

Robots operating in everyday settings must reason about objects, locations and tasks while remaining safe and reliable. Many approaches have emerged in embodied AI, from classical symbolic planners to powerful neural policies, but none alone can meet the needs of production robotics. This white paper presents a unified Scene Grammar architecture that integrates these paradigms around a typed scene graph and predicate ontology. It explains how high‑level language instructions are parsed into formal goals, how different planning modules interact with the world model, how learned controllers run under a safety shield, and how self‑supervision can compound data. Examples from Mbodi’s open‑source libraries illustrate concrete mechanisms for building and using the architecture, and selected Linear issues demonstrate how real‑world failures shape priorities.

## 1. Introduction

Robots are leaving structured factories and entering warehouses, kitchens and hospitals. In these environments success is binary: either the robot loaded the correct item onto the shelf or it did not. A 0.87 confidence score is not actionable. At the same time, tasks are highly compositional – one day the robot must stack cups on a tray, the next it must carry a loaded tray to a person. Traditional systems address these needs separately: symbolic planners provide verifiable logical guarantees but lack flexibility; end‑to‑end neural policies adapt quickly but cannot explain or reliably recover from mistakes. Our Scene Grammar architecture combines these strengths by representing the world as a typed, hierarchical scene graph, defining goals and skills as logical predicates and operators, and integrating planners, memory retrieval and learned policies into a modular pipeline. The result is a system that can plan, execute, monitor and learn from its actions while remaining interpretable and extensible.

### 1.1 Motivation

Mbodi's internal survey of embodied AI approaches showed that techniques like task‑and‑motion planning (TAMP), behavior trees, retrieval‑augmented planning and diffusion policies are complementary rather than competing. They can operate on the same world model and predicate ontology provided the representation is expressive and typed. Our libraries – embodied‑agents and embodied‑data – provide the building blocks for this representation. embodied‑agents offers modular agents for language, motion and sensory modalities with a simple act interface and supports asynchronous remote execution
GitHub
. It includes retrieval‑augmented generation (RAG) tools to query a database of robot skills and convert natural language instructions into structured actions
GitHub
. embodied‑data defines typed coordinates, poses and scene graph entities, and implements fast frame transforms
GitHub
. By aligning these libraries with our scene grammar, we can unify perception, planning and control.

## 2. Real-World Requirements

### 2.1 Verifiable Success

The core of our architecture is a discrete success criterion. Goals are expressed as logical formulae (e.g. $\mathrm{on}(\text{cup},\,\text{shelf})\ \wedge\ \mathrm{clear}(\text{table})$), and after execution we evaluate whether the final scene graph satisfies this formula ($G\ \vDash\ \varphi$). Integrated task‑and‑motion planners use the same logical vocabulary for high‑level search and incorporate continuous feasibility checks to ensure geometric validity (Kaelbling & Lozano‑Pérez, 2011: https://journals.sagepub.com/doi/10.1177/0278364910369189). This binary notion of success avoids the ambiguity of neural confidence scores and allows us to catch hallucinated plans before they cause harm.

### 2.2 Compositional Generalization

Tasks are combinations of known objects and skills. We therefore design operators around predicates, not pixels. If the system has a grasp skill and a pour skill, it can perform pour water from cup into bowl by composing grasp(cup), pour(cup, bowl) and relevant preconditions, even if it never saw this exact combination. Benchmarks like ClevrSkills[^2] show that large neural models fail on recombining known skills. Our predicate ontology and scene graph explicitly support recombination: nodes represent typed objects and edges represent relations, and planning operates by satisfying and modifying predicates rather than memorizing sequences.

### 2.3 Latency and Responsiveness

Robots must react in milliseconds when grasping a slipping object but can deliberate for seconds when planning an assembly. We adopt a hybrid control paradigm: a reactive layer uses learned policies to handle routine or time‑critical behaviour, while a deliberative layer performs symbolic search and retrieval when encountering novel situations. Both layers read and update the same scene graph, ensuring consistency. Our safety shield (Section 6) monitors constraints at high frequency and can override learned policies if they propose unsafe actions.
arxiv.org

### 2.4 Auditability and Explainability

Every decision in the system is grounded in predicates and operators. We log preconditions, chosen actions, resulting predicate values and goal satisfaction. When a plan fails, we know which predicate was violated and can debug accordingly. Because predicates correspond to human concepts (e.g., holding(x), clear(y)), we can generate natural explanations: “I did not pick up the red cup because I needed a free hand to open the faucet first.” Such transparency is critical for user trust and for meeting regulatory requirements.

## 3. Scene Graph and Predicate Ontology

### 3.1 Typed Scene Graph

Our world model is a typed directed graph where nodes are SceneObject instances and edges are Relation instances. Each node has a unique name, type and attributes (e.g., pose, colour). Relations are typed (e.g., ON, IN, CONNECTED_TO). Paths like kitchen.table.cup provide fully qualified names for objects. We enforce acyclicity for part‑of/containment hierarchies.
A distinctive feature of Mbodi’s implementation is that frames (coordinate systems) are represented as a separate hierarchy that forms a tree rooted at world (unique parent per frame). User‑level poses (Pose6D, Point, etc.) are not nodes; they store a reference frame name and a cached origin in the world frame. Lookup operations traverse this frame tree: Pose6D.absolute() composes the local pose with the world pose of its reference frame, and Pose6D.relative(other) computes the pose of one coordinate relative to another using quaternion math. This design ensures that every coordinate has a unique path to the world frame and that temporary anchors remain lightweight.

#### Example: Creating and Transforming Objects

The following Python snippet illustrates how to build a simple scene with the embodied‑data types and compute relative poses:

```python
from embdata.coordinate import Pose6D
from embdata.sense.scene import SceneObject

# Create a world and two frames
world = SceneObject("world")
table = SceneObject("table", parent=world, pose=Pose6D([1,0,0,0,0,0]))  # at x=1
cup = SceneObject("cup", parent=table, pose=Pose6D([0,0,0.2, 0,0,0]))  # 20cm above table

# Compute cup pose in world and table frames
cup_world = cup.pose.absolute()          # Pose in world coordinates
cup_in_table = cup.pose.relative(table)  # Should return approximately [0,0,0.2]
```

This example emphasises that adding an object under a parent automatically updates its pose metadata via SceneObject.add_child and that relative/absolute operations are simple method calls on typed poses.

### 3.2 Predicate Ontology

On top of the scene graph we define a finite set of predicates. Each predicate has a name, arity and type signature, e.g., on(x: Object, y: Surface), inside(x: Object, y: Container), clear(y: Surface) and holding(x: Object). Predicates are either stored directly (as labelled edges) or computed from the graph (e.g., clear(y) is true when no object is on y). The ontology also encodes invariants: an object cannot be simultaneously on(a,b) and inside(a,c); certain relations are exclusive; and we treat on(·,·) as non‑transitive while deriving above/stack‑height via support chains.
Goals are logical formulae over predicates. A typical goal might be:

\[
\mathrm{on}(\text{cup1},\,\text{shelf.level2})\ \wedge\ \mathrm{on}(\text{cup2},\,\text{shelf.level2})\ \wedge\ \mathrm{clear}(\text{table})
\]

Success is defined as the final graph satisfying the formula,

\[
G \vDash \varphi
\]

which we evaluate after each action.
Operators are state transitions described by preconditions and effects. A Pick(obj, loc) operator might require clear(obj) ∧ reachable(obj) and set holding(obj) true while removing on(obj, loc). These definitions allow symbolic search algorithms to explore the space of predicate assignments.

### 3.3 Schema Validation

State updates from perception or execution are validated against the ontology. Type constraints ensure that only permissible relations can be added (e.g., on(robot1, cup1) is disallowed), cardinality constraints limit the number of objects in containers, and invariants prevent contradictory states. Validation is performed at the scene‑graph level before predicates are updated, ensuring the world model remains consistent.

## 4. Language Understanding and Instruction Parsing

Robots often receive instructions in natural language. Our architecture converts these instructions into formal goals and optional high‑level plan sketches.

### 4.1 Grammar-Based Parsing

We combine classical NLP with controlled large language models (LLMs): dependency parsing and semantic role labelling identify entities and actions; a domain‑specific grammar maps phrases to predicates and objects; and an LLM, constrained to output JSON adhering to our ontology, fills in ambiguities. This yields a goal formula φ and a set of suggested operators. For example:
User: “Stack the red cup on the top shelf and close the cupboard.”
Parser output:

\[
\varphi = \mathrm{on}(\text{red\_cup},\,\text{cupboard.top\_shelf})\ \wedge\ \mathrm{closed}(\text{cupboard})
\]

Plan sketch: [Pick(red_cup), Move(red_cup, cupboard.top_shelf), Close(cupboard)].
Because the grammar is defined over our predicate ontology, parsing errors are caught by schema validation.

### 4.2 Retrieval-Augmented Instructions

When instructions refer to skills not explicitly encoded in the grammar (e.g., “wave at the audience”), we use a retrieval‑augmented generation (RAG) pipeline. Mbodi’s RagAgent stores natural language descriptions of robot skills in a vector database and retrieves the most relevant documents given an instruction. The retrieved text is prepended to the user’s query before sending it to a language agent. The example script below illustrates this pattern:

```python
from mbodied.agents.language import LanguageAgent, RagAgent
from mbodied.robots import SimRobot

rag = RagAgent(collection_name="skills", path="./chroma", distance_threshold=1.5)
# Insert skill descriptions
rag.upsert([
    "You are a robot. To wave at the audience, go left and right by 0.1m for 3 times.",
    "You are a robot. To high five, move up and then forward by 0.2m."
])

language_agent = LanguageAgent(model_src="openai", context="Respond with actions JSON…")
robot = SimRobot()

instruction = "Hi robot, wave at the audience please."
instruction_with_rag = rag.act(instruction, n_results=1)  # retrieves the wave skill:contentReference[oaicite:11]{index=11}
result = language_agent.act_and_parse(instruction_with_rag)
robot.do(result.actions)
```

The RagAgent automatically retrieves the relevant skill description and the language agent produces actions conforming to a schema; the SimRobot executes them. This mechanism demonstrates how retrieval planning can bias instruction parsing and reduce planning time by reusing previously encoded behaviours
GitHub
.

## 5. Planning and Control Modules

### 5.1 Task-and-Motion Planning

TAMP integrates symbolic search with continuous motion planning. At the symbolic level, it uses our predicate ontology to search over operators. At each step, it calls a motion planner to find a collision‑free trajectory that satisfies geometric constraints. Kaelbling and Lozano‑Pérez’s work on integrated task‑and‑motion planning shows how logical goals and continuous feasibility tests are combined (https://journals.sagepub.com/doi/10.1177/0278364910369189). Our system leverages this technique by mapping symbolic operators to parameterized motion primitives and using the scene graph to compute reachability and collision constraints.

### 5.2 Behavior Trees

Behavior trees (BTs) compile plans into reactive, hierarchical graphs. Selectors and sequences orchestrate the execution order; decorators implement guards and retries. BTs are modular, easy to understand and modify, and they combine the advantages of finite state machines with the flexibility of hierarchical task networks. Our planners emit BTs automatically from high‑level plans and also allow learned BT leaves. Control flow nodes ensure that preconditions are checked before executing children. The same scene predicates that drive planning are evaluated at run time to decide whether to repeat, skip or abort nodes.

### 5.3 Retrieval-Augmented Planning

Retrieval‑augmented planning stores previously executed trajectories indexed by the predicate context and recalls them to guide new searches. For LLM agents, see RAP (Kagaya et al., 2024: https://arxiv.org/abs/2402.03610) and RaDA (Kim et al., 2024: https://aclanthology.org/2024.findings-acl.123/). In motion planning, experience retrieval improves sampling‑based planners (Chamzas et al., 2022: https://ieeexplore.ieee.org/document/9812004) and experience graphs bias planners towards reusing past paths while preserving guarantees (Phillips et al., 2013: https://www.ri.cmu.edu/publications/e-graphs-bootstrapping-planning-with-experience/). Our implementation uses a memory of 〈state, action, next_state〉 tuples keyed by a hash of predicate assignments. When the planner encounters a familiar context, it retrieves a sequence of operators and either uses it directly or uses it as a heuristic to bias search. The RAG example in Section 4.2 shows a simple retrieval mechanism for natural language instructions; retrieval planning generalizes this idea to predicate contexts.

### 5.4 Learned Policies under a Safety Shield

Learned controllers provide smooth, reactive behaviour but can violate constraints when faced with novel states. We train diffusion policies and reinforcement learning policies on verified execution traces. Diffusion policies model robot action distributions as conditional denoising processes and achieve strong performance on diverse visuomotor tasks (Chi et al., 2023: https://arxiv.org/abs/2303.04137). However, they lack explicit constraint handling. We wrap these policies with a safety layer that solves a quadratic program to minimally adjust the commanded action so that it satisfies linear constraints such as collision avoidance and joint limits (Dalal et al., 2018: https://arxiv.org/abs/1801.08757). Differentiable QP layers may be used when joint training is desired (Amos & Kolter, 2017: https://arxiv.org/abs/1703.00443; Agrawal et al., 2019: https://arxiv.org/abs/1910.09529). Thus, our safety shield monitors predicate‑based constraints (e.g., NOT(collision(robot_arm, table))) and either vetoes or modifies actions to guarantee safety.

### 5.5 Mixture-of-Experts and Hierarchical RL

Modern systems benefit from specialization: vision modules excel at perception, large language models at reasoning, and motor policies at control. A mixture‑of‑experts (MoE) architecture uses a trainable gating network to select a small subset of experts for each input, enabling capacity scaling with sparse activation. In our system, experts correspond to specialized perception models, planners and low‑level controllers; the gating network selects experts based on the predicate context and sensor data.
Hierarchical reinforcement learning (HRL) formalizes the notion of options – temporally extended actions defined by initiation sets, internal policies and termination conditions. Sutton et al. prove that options can be integrated with primitive actions in planning and learning
www-anw.cs.umass.edu
. We treat each learned skill (e.g., grasp, pour) as an option with predicates defining when it can be invoked and when it terminates. The high‑level policy selects among options, and new options can be spawned when retrieval planning fails repeatedly in a specific context. Combining MoE and HRL yields a scalable system that can dynamically allocate computation and add new skills as needed.

## 6. Perception and Data Pipeline

Robust perception is essential for an accurate scene graph. Our vision pipeline uses depth cameras, segmentation models and object detectors to update object poses and attributes. embodied‑agents provides sensory agents with support for models like YOLO, Segment Anything 2 and DepthAnything
GitHub
. These agents publish updates to the scene graph via the publish/subscribe layer. Using the typed coordinate classes from embodied‑data, we convert raw detections into Pose6D instances with reference frames; coordinate transformations (absolute/relative) follow the rules described in the Transform & Scene‑Graph Guide
GitHub
.
We also leverage cross‑modal checks: if two cameras disagree on an object’s pose beyond a threshold, we mark the pose as uncertain and trigger a re‑observation. Schema validation prunes impossible configurations early (e.g., two objects occupying the same slot) so that planning operates on consistent states.

## 7. Self-Supervision and Data Compounding

Every successful execution under the scene grammar yields a clean, labelled trajectory: a sequence of states, actions and predicates that culminates in

\[
G \vDash \varphi
\]

These trajectories serve as training data for perception models, diffusion policies and retrieval planners. The self‑play dynamic of AlphaZero, which iteratively improved by playing against itself, inspires this cycle: the robot uses verified executions to train better models, which in turn produce more successes, compounding data quality.Because each trace is associated with a goal formula and predicate context, the data is structured and easily queryable. Future work includes augmenting this self‑supervision with synthetic augmentation (e.g., simulating extra views or noise) and active data collection where the robot deliberately seeks out edge cases to improve its models.

## 8. Implementation Phases and Current Work

### 8.1 Phase 1 – Robust Symbolic Core

We are currently building the foundational substrate:
Scene Graph & Ontology: Implement the typed scene graph and predicate ontology using embodied‑data for coordinate handling and embodied‑agents for sensor integration.
Deterministic Planner: Develop a symbolic planner that searches over predicate states and enforces schema validation. Plan operators will be defined in a domain description file with preconditions and effects.
Safety Shield: Implement the safety layer that monitors constraints and vetoes actions.
arxiv.org
Debugging Tools: Provide visualization utilities to inspect scene graphs and predicate truth assignments; we use the visualize_scene_graph.py tool from embodied-data-corp for this purpose.

### 8.2 Phase 2 – Learned Components and Retrieval

Diffusion and RL Policies: Train diffusion and reinforcement learning controllers on verified trajectories and deploy them under the safety shield.
Retrieval Memory: Build a memory module for retrieval‑augmented planning. Store executed trajectories keyed by predicate contexts; design heuristics for matching and for biasing search; integrate RAG for language instructions.
Mixture‑of‑Experts Router: Implement a gating network to select perception models and control policies based on the current predicate context and sensor data.
Dataset Recording: Enable automatic dataset recording and upload using embodied‑agents
GitHub
; support asynchronous remote inference for heavy models
GitHub
.

### 8.3 Phase 3 – Autonomous Skill Acquisition

Hierarchical RL: Frame the MoE architecture as an options framework
www-anw.cs.umass.edu
 and learn both the gating policy and the option policies.
Skill Incubation: Spawn new experts automatically when the planner detects repeated failures in a specific predicate region. This parallels the MoE Incubator concept: cluster failure contexts, create a new expert specializing in that cluster, and train it using self‑supervised trajectories.
Active Evaluation: Define tasks that deliberately challenge compositional generalization and safety; measure performance metrics across phases.

### 8.4 Example Issue Driving Improvements

Issue MBO‑88 in our Linear backlog documents failures observed in a June 9th demo: the robot applied too little force when picking up a light bulb, causing it to slip; the gripper did not open fully due to a hardware issue; a Clorox bottle’s pose was mis‑estimated and not updated after manual correction; the light bulb pose was inaccurate; and trajectory planning did not account for collisions【943723223284060†L18-L21】. These observations highlight priorities for Phase 1 and 2: improved force control and compliance, more robust perception with frame updates, collision‑aware motion planning and reliable gripper hardware. By encoding these failure contexts in the retrieval memory and updating the safety constraints, we ensure the system learns from operational experience.



Research on TAMP (Kaelbling & Lozano‑Pérez, 2011: https://journals.sagepub.com/doi/10.1177/0278364910369189), behavior trees (Iovino et al., 2022: https://www.sciencedirect.com/science/article/pii/S0921889022000513), retrieval planning (Kagaya et al., 2024: https://arxiv.org/abs/2402.03610; Chamzas et al., 2022: https://ieeexplore.ieee.org/document/9812004; Phillips et al., 2013: https://www.ri.cmu.edu/publications/e-graphs-bootstrapping-planning-with-experience/), diffusion policy (Chi et al., 2023: https://arxiv.org/abs/2303.04137), safety layers (Dalal et al., 2018: https://arxiv.org/abs/1801.08757; Amos & Kolter, 2017: https://arxiv.org/abs/1703.00443; Agrawal et al., 2019: https://arxiv.org/abs/1910.09529), mixture‑of‑experts (Shazeer et al., 2017: https://arxiv.org/abs/1701.06538) and hierarchical RL options (Sutton et al., 1999: https://www.sciencedirect.com/science/article/pii/S0004370299000521) offers proven techniques for each module.
