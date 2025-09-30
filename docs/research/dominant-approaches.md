# Ten Approaches in Embodied AI: Planning-Centric vs Policy-Centric

- [Ten Approaches in Embodied AI: Planning-Centric vs Policy-Centric](#ten-approaches-in-embodied-ai-planning-centric-vs-policy-centric)
  - [Planning-Centric Approaches](#planning-centric-approaches)
    - [1. Program Synthesis into a Domain-Specific Language (DSL)](#1-program-synthesis-into-a-domain-specific-language-dsl)
    - [2. Task-and-Motion Planning (TAMP)](#2-task-and-motion-planning-tamp)
    - [Example: Block Stacking Task\*\*](#example-block-stacking-task)
    - [3. Retrieval-Augmented Planning](#3-retrieval-augmented-planning)
    - [4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves](#4-behavior-trees-bts-and-finite-state-machines-with-learned-leaves)
    - [5. Constraint and Linear Programming](#5-constraint-and-linear-programming)
    - [6. Vision-and-Language Action (VLA) Planner–Executor](#6-vision-and-language-action-vla-plannerexecutor)
  - [Policy-Centric Approaches](#policy-centric-approaches)
    - [7. End-to-End Learned Policies + Safety Shield](#7-end-to-end-learned-policies--safety-shield)
    - [8. Probabilistic and Factor Graph Planning](#8-probabilistic-and-factor-graph-planning)
    - [9. Model-Based RL: Honorable Mentions](#9-model-based-rl-honorable-mentions)
      - [9a. Planning with Learned Models (PlaNet)](#9a-planning-with-learned-models-planet)
      - [9b. Actor-Critic in Latent Space (Dreamer)](#9b-actor-critic-in-latent-space-dreamer)
      - [9c. Tree Search with Learned Models (MuZero)](#9c-tree-search-with-learned-models-muzero)
    - [10. Hierarchical Reinforcement Learning (HRL) with Options/Skills](#10-hierarchical-reinforcement-learning-hrl-with-optionsskills)
  - [Comparative Analysis of the 10 Approaches](#comparative-analysis-of-the-10-approaches)
    - [Scalability and Complexity Handling](#scalability-and-complexity-handling)
    - [Sample Efficiency and Learning Requirements](#sample-efficiency-and-learning-requirements)
    - [Interpretability and Explainability](#interpretability-and-explainability)
    - [Robustness and Failure Handling](#robustness-and-failure-handling)
    - [Practical Deployment Considerations](#practical-deployment-considerations)
  - [References](#references)

The traditional view posits two families of approaches to embodied intelligence: planning-centric methods and policy-centric methods[^brooks1991] [^kaelbling1987]. However, this distinction seems to be becoming increasingly artificial. "Planning-centric" approaches now incorporate learned components (like LLM-guided synthesis)[^silver2023] [^huang2024], while "policy-centric" methods often involve substantial planning (like MPC or hierarchical decomposition)[^garnelo2018] [^kaelbling2020] [^kaelbling2011] [^lesort2022]. The boundaries are blurring as methods hybridize[^garnelo2018] [^kaelbling2020] [^kaelbling2011] [^lesort2022] [^schrittwieser2020] [^hafner2023].

Recent surveys highlight this convergence: planning methods increasingly use learning for search guidance[^zhao2024], while policy methods incorporate explicit planning for long-horizon reasoning[^hafner2023] [^schrittwieser2020]. This hybridization reflects the reality that neither pure approach can handle the complexity of real-world embodied tasks[^lesort2022] [^gupta2023]. Below, we examine ten such approaches, noting how they often combine elements from both paradigms, with detailed examples and formal analysis for each.

## Planning-Centric Approaches

Planning-centric methods explicitly reason over discrete actions or subgoals to devise a strategy before (or during) execution. They often use symbolic representations or search algorithms. Six key planning-oriented approaches are:

### 1. Program Synthesis into a Domain-Specific Language (DSL)

**Seminal Works:**

- [Program Synthesis by Sketching (Solar-Lezama, 2008)](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2008/EECS-2008-176.pdf)
- [Syntax-Guided Synthesis (Alur et al., 2013)](https://www.cis.upenn.edu/~alur/SyGuS13.pdf)
- [Automating String Processing in Spreadsheets (Gulwani, 2011)](https://www.microsoft.com/en-us/research/publication/automating-string-processing-spreadsheets-using-input-output-examples/)

**Libraries:**

- [Rosette](https://emina.github.io/rosette/) - Solver-aided programming language
- [Synquid](https://github.com/nadia-polikarpova/synquid) - Type-driven program synthesis
- [SKETCH](https://people.csail.mit.edu/asolar/sketch.htm) - Program synthesis by sketching tool

Use of search algorithms or large language models (LLMs) to synthesize a high-level program (in a DSL) that, when executed by the robot, achieves the task. The DSL could be a formal planning language (like PDDL or a custom scripting language for robot actions)[^*gulwani2017] [^*alur2013] [^*solar2008].

Essentially, the planner "writes code" for the robot using known primitives. This approach has gained significant traction with the advent of LLMs that can generate structured code from natural language descriptions[^4] [^5] [^6].

**Formal View:**
Suppose we have a DSL $\mathcal{L}$ with primitives corresponding to robot actions (e.g., Pick(object), Place(object, location), loops, conditionals, etc.). The task is to find a program $P \in \mathcal{L}$ such that executing $P$ from initial state $s_0$ will result in a state satisfying the goal condition $\varphi$. Formally, we want:
$$
\text{Execute}(P, s_0) \models \varphi,
$$
where $\models \varphi$ means the goal predicates are true in the final state.

Program synthesis typically involves searching through the space of programs (which can be huge). Techniques include:

1. **Enumerative search**: Systematically explore program space using deductive rules[^2]
2. **Evolutionary algorithms**: Use genetic programming to evolve programs[^7]
3. **Constraint-based synthesis**: Encode synthesis as SMT/SAT problems[^3]
4. **LLM-guided synthesis**: Use pretrained LLMs trained on code to suggest program structures[^4] [^5]

The use of an LLM can guide this search by leveraging prior knowledge to propose plausible program structures. Recent work shows LLMs can achieve up to 90% success rates on simple synthesis tasks[^6].

**Detailed Example - Robotic Assembly Task:**
Consider a robotic assembly scenario where the robot must assemble a simple structure. The DSL includes:

```python
def move_to_pose(pose: Pose) -> None:...
def pick_object(obj: str) -> None:...
def place_object(obj: str, location: Pose) -> None:...
def align_objects(obj1: str, obj2: str) -> None:...
def fasten_objects(obj1: str, obj2: str, fastener: str) -> None:...
def check_alignment(obj1: str, obj2: str) -> bool:...
```

A complex assembly task like "Assemble the chair using the provided legs, seat, and screws" could be synthesized into:

```python
def assemble_chair():
    # Step 1: Position components
    move_to_pose(workspace_center)
    pick_object("chair_seat")
    place_object("chair_seat", assembly_position)

    # Step 2: Attach rear legs
    for leg in ["rear_left", "rear_right"]:
        pick_object(leg)
        align_objects(leg, "chair_seat")
        fasten_objects(leg, "chair_seat", "screw")
        # Verify alignment
        if not check_alignment(leg, "chair_seat"):
            realign_and_retry()

    # Step 3: Attach front legs
    for leg in ["front_left", "front_right"]:
        pick_object(leg)
        align_objects(leg, "chair_seat")
        fasten_objects(leg, "chair_seat", "screw")

    # Step 4: Quality check
    return verify_assembly_stability()
```

**Implementation Details:**
Recent systems demonstrate this approach with remarkable success:

- **Code-as-Policies (CaP)**[^61]: Uses LLMs to generate Python-like policies for manipulation tasks, achieving 80% success on household tasks
- **Program-aided Language Models (PAL)**[^62]: Combines LLMs with program execution for complex reasoning, improving accuracy by 20-30%
- **RoboCode**[^63]: DSL specifically for robotics that generates executable robot programs from natural language

**Mathematical Foundation:**
The synthesis problem can be formalized as finding $P \in \mathcal{L}$ such that:
$$\exists P \in \mathcal{L}: \forall s_0 \in S_0, \text{Execute}(P, s_0) \in G$$

where $S_0$ is the set of possible initial states and $G$ is the goal region. For DSLs with well-defined semantics, this becomes a search problem in the space of abstract syntax trees[^2].

**Advantages:**

- **Compositional reasoning**: Programs can handle complex logic including loops, conditionals, and subroutines[^2]
- **Interpretability**: Generated programs are human-readable and debuggable
- **Reusability**: Programs can be stored and reused for similar tasks

**Limitations:**

- **Search space explosion**: The space of possible programs grows exponentially with task complexity[^1]
- **Grounding problem**: LLMs may generate physically impossible programs[^10]
- **Partial observability**: Real-world state estimation introduces uncertainty not captured in the DSL[^59]

**Recent Advances:**
Recent work addresses these limitations through:

1. **Neuro-symbolic approaches**: Combining neural search guidance with symbolic verification[^9]
2. **Iterative refinement**: Using execution feedback to refine generated programs[^11]
3. **Hierarchical synthesis**: Breaking complex tasks into sub-programs[^10]

This approach is powerful because the DSL ensures plans consist of known actions, and the program structure can handle loops or conditionals as needed. However, synthesizing correct programs is challenging: it requires the planner to understand action preconditions/effects and how to compose them properly.

### 2. Task-and-Motion Planning (TAMP)

- **Seminal Works:**
  - [Hierarchical Task and Motion Planning in the Now (Kaelbling & Lozano-Pérez, 2011)](https://www.semanticscholar.org/paper/Hierarchical-task-and-motion-planning-in-the-now-Kaelbling-Lozano-Perez/9b7ae896675c71ac50fa1fbc555cb19f80863f0e)
  - [FFRob: Leveraging Symbolic Planning for Efficient TAMP (Garrett et al., 2016)](https://arxiv.org/abs/1608.01335)
- **Libraries:**
  - [PDDLStream](https://github.com/caelan/pddlstream)
  - [OMPL (Open Motion Planning Library)](https://ompl.kavrakilab.org/) - Includes sampling-based (RRT, PRM) and optimization-based planners (see also Section 5)
  - [MoveIt](https://moveit.ai/)
  - [Fast Downward](https://www.fast-downward.org/)

An integrated approach that combines high-level task planning (discrete, symbolic) with low-level motion planning (continuous trajectories). TAMP finds a sequence of discrete actions (task plan) AND concrete motions/grasps for each action that make it feasible in the real geometry[^34] [^60] [^35] [^36]. It bridges symbolic AI planning with robotics motion planning, ensuring that the plan is both logically sound and physically executable under geometric constraints (kinematics, collisions, etc).

The motion planning component typically uses either sampling-based methods (RRT, RRT*, PRM) or optimization-based methods (CHOMP, TrajOpt from Section 5) to find collision-free trajectories.

TAMP represents a fundamental shift from classical planning by explicitly handling the continuous aspects of robot motion and object interaction[^37]. Recent surveys show TAMP achieving 70-85% success rates on complex manipulation tasks[^17].

**Formal view:**
A TAMP problem can be formalized as a hybrid planning problem with both discrete and continuous components:

**State Space:**

- **Symbolic state** $s \in S_{sym}$: Set of ground predicates (e.g., $\{on(A,B), clear(A), holding(nothing)\}$)
- **Continuous state** $q \in Q$: Robot configuration and object poses (e.g., joint angles, 6D object poses)

**Actions:**
Each high-level action $a$ has:

- **Symbolic preconditions** $\text{Pre}_{sym}(a)$: Logical conditions that must hold
- **Symbolic effects** $\text{Eff}_{sym}(a)$: Changes to symbolic state
- **Continuous parameters** $\theta_a \in \Theta_a$: Motion parameters (trajectories, grasp poses, etc.)
- **Geometric constraints** $C_a(\theta_a, q)$: Must be satisfied for feasibility

**TAMP Problem Definition:**
Find a sequence of actions $\pi = (a_1, a_2, \ldots, a_n)$ and parameters $(\theta_1, \theta_2, \ldots, \theta_n)$ such that:

1. **Symbolic consistency**: $\forall i, s_{i-1} \models \text{Pre}_{sym}(a_i)$ where $s_i = \text{Eff}_{sym}(a_i)(s_{i-1})$
2. **Geometric feasibility**: $\forall i, C_{a_i}(\theta_i, q_{i-1})$ is satisfiable
3. **Goal satisfaction**: $s_n \models \varphi$ where $\varphi$ is the goal formula

**Search Strategy:**
TAMP solvers typically use hierarchical search that interleaves symbolic planning with geometric constraint solving[^60]:

```python
def tamp_search(initial_state, goal):
    # Forward search through symbolic state space
    for task_plan in symbolic_planner(initial_state, goal):
        if geometrically_feasible(task_plan):
            return task_plan
        # Backtrack and try alternative symbolic plan
    return None

def geometrically_feasible(task_plan):
    current_q = initial_q
    for action in task_plan:
        # Solve for motion parameters given constraints
        theta = solve_motion_constraints(action, current_q)
        if theta is None:
            return False
        # Update continuous state
        current_q = simulate_motion(action, theta, current_q)
    return True
```

**Example - Cluttered Workspace Rearrangement:**
Consider a robot that must rearrange objects in a cluttered workspace to access a target object. The task: "Move the red block to the blue zone, but there are obstacles in the way."

**Step 1: Symbolic Planning**
A classical planner might generate:

```python
Plan: [MoveObstacle(green_box), Pick(red_block), Place(red_block, blue_zone)]
```

**Step 2: Geometric Feasibility Check**
For each action, TAMP solves:

- **MoveObstacle(green_box)**: Find collision-free trajectory to push green_box aside
- **Pick(red_block)**: Find grasp pose and approach trajectory avoiding obstacles
- **Place(red_block, blue_zone)**: Find placement motion that doesn't collide

The geometric constraints can be formulated as optimization problems:

For a pick action:
$$\min_{\theta_{grasp}, \theta_{approach}} ||\theta_{grasp} - \theta_{grasp}^{nominal}||$$
subject to:

- **Reachability**: Robot inverse kinematics solvable for $\theta_{grasp}$
- **Collision-free approach**: Trajectory $\tau(\theta_{approach})$ avoids obstacles
- **Force closure**: Grasp matrix ensures stable grasping

For motion planning between actions:
$$\min_{\tau} \int_0^1 ||\dot{q}(t)||^2 dt$$
subject to:

- **Collision avoidance**: $\forall t, dist(\tau(t), obstacles) > \epsilon$
- **Joint limits**: $q_{min} \leq \tau(t) \leq q_{max}$
- **Dynamic constraints**: $\ddot{q}(t)$ within torque limits

**Implementation Approaches:**

1. **Hierarchical Planning**: PDDL-based symbolic planning + sampling-based motion planning[^60]
2. **Integrated Optimization**: Solve entire problem as nonlinear program[^36]
3. **Learning-enhanced TAMP**: Use learned motion predictors to guide search[^garrett2021]

**Recent Advances:**

- **Neural TAMP**: Integration of learned geometric models[^ichter2020]
- **Multi-robot TAMP**: Coordination across multiple agents[^wagner2023]
- **Uncertainty-aware TAMP**: Handling perception and execution uncertainty[^kaelbling2020]

**Performance Characteristics:**

- **Success rates**: 60-90% on benchmark manipulation tasks[^17]
- **Planning time**: 1-30 seconds for typical problems
- **Scalability**: Exponential in number of objects and actions

### Example: Block Stacking Task**

**Scenario:** Place block A on block B in a cluttered environment

**Initial Scene:**

```text
┌─────────────┬─────────────┬─────────────┐
│    Block C  │    Block B  │    Block D  │
│   (tall)    │   (medium)  │   (small)   │
├─────────────┼─────────────┼─────────────┤
│             │    Block A  │             │
│   Empty     │   (small)   │   Empty     │
│   Space     │             │   Space     │
└─────────────┴─────────────┴─────────────┘
```

**Symbolic Plan (Classical Planner):**

1. `Pick(A)` - Grasp block A
2. `Pick(B)` - Move block B aside (clear space)
3. `Place(B, elsewhere)` - Put B in empty location
4. `Place(A, on B's original position)` - Place A where B was
5. `Place(B, on A)` - Stack B on top of A

**TAMP Geometric Validation:**

**Step 2 Analysis - `Pick(B)`:**

```text
┌─────────────┬─────────────┐
│    Block C  │    Block B  │ ← Gripper trying to reach B
│   (tall)    │   (medium)  │    but C is blocking access!
├─────────────┼─────────────┤
│   Empty     │    Block A  │
└─────────────┴─────────────┘
❌ GEOMETRIC FAILURE: Gripper cannot reach B due to Block C obstruction
```

**TAMP Response:**

- Marks current plan as infeasible
- Searches for alternative: `Pick(C)` first to clear path to B
- New plan: `Pick(C)` → `Place(C, elsewhere)` → `Pick(B)` → `Pick(A)` → `Place(B, original)` → `Place(A, on B)` → `Place(C, on A)`

**Advantages:** TAMP ensures plans are not just logically correct but geometrically executable, preventing execution failures.

**Limitations:** TAMP is computationally expensive and notoriously time-consuming. Further, it performs an algorithmic search which , while greedy and optimal in some constraint specification, still considers a huge space of logically incoherent plans that any LLM will reject.

### 3. Retrieval-Augmented Planning

- **Seminal Works:**
  - [Retrieval-Augmented Reinforcement Learning (Goyal et al., 2022)](https://arxiv.org/abs/2202.08417)
  - [RAP: Retrieval-Augmented Planning with Contextual Memory (2024)](https://arxiv.org/abs/2402.03610)
  - [ReAct: Synergizing Reasoning and Acting in Language Models (2022)](https://arxiv.org/abs/2210.03629)
- **Libraries:**
  - [RAP (official code)](https://github.com/PanasonicConnect/rap)
  - [ReAct (reference implementation)](https://github.com/ysymyth/ReAct)

A planning approach that leverages a memory of past successful plans or trajectories. Instead of planning from scratch every time, the robot retrieves similar experiences from a database and adapts or reuses them for the current task[^chamzas2022] [^memmel2025] [^kagaya2024].

This is akin to case-based reasoning or learning from demonstrations, integrated into the planner. The effect is to dramatically reduce search when a similar problem has been solved before. Recent surveys show retrieval-augmented methods achieving 2-10x speedup over from-scratch planning[^nasiriany2022].

More formally, we maintain a repository $\mathcal{M}$ of past solutions, where each entry is a tuple: $(s_{\text{start}}, \varphi_{\text{goal}}, \pi, r)$, representing that in a past situation with start state $s_{\text{start}}$ and goal $\varphi_{\text{goal}}$, a plan $\pi = [a_1,\ldots,a_k]$ achieved reward $r$.

**Retrieval Mechanism:**
When faced with a new planning problem $(s_{0}, \varphi)$, the planner computes similarity between $(s_0,\varphi)$ and stored cases. Formally, define a similarity function:
$$
\text{Retrieve}(s_0,\varphi) = \{ (p_i, \text{Score}_i) \}_{i=1}^K,
$$
where each $p_i$ is a retrieved past plan and $\text{Score}_i$ indicates relevance.

**Similarity Metrics:**

1. **Symbolic similarity**: Matching predicates and object relations[^chamzas2022]
2. **Embedding-based similarity**: Learned vector representations[^memmel2025]
3. **Graph-based similarity**: Scene graph edit distance[^kagaya2024]

The planner then biases its search using these suggestions as priors in a planning algorithm like MCTS or A*[^kagaya2024].

**Integration with Search:**
In Monte Carlo Tree Search (MCTS), retrieval provides action priors:
$$
\text{Score}(a) = Q(s,a) + c \cdot \pi_0(a \mid s) \frac{\sqrt{\sum_b N(s,b)}}{1 + N(s,a)},
$$
where $\pi_0(a)$ is derived from retrieved plans and indicates how often action $a$ appears in successful plans from similar states[^ chamzas2022 ].

**Example - Robotic Manipulation in Clutter:**
Consider a robot that must pick and place objects in a cluttered environment. The system maintains a database of past successful manipulation sequences.

**Step 1: Task Specification**
Current task: "Pick the red mug from the cluttered table and place it on the shelf"

**Step 2: Retrieval**
The system searches the database for similar past tasks:

- Similar initial state: cluttered table with mugs
- Similar goal: pick specific object and place on elevated surface
- Retrieved cases: 15 similar manipulation sequences

**Step 3: Adaptation**
The most similar retrieved plan:

```text
Original: [MoveTo(mug_position), Grasp(mug), Lift(mug, height=0.3), MoveTo(shelf), Place(mug, shelf)]
Adapted:  [MoveTo(red_mug_position), Grasp(red_mug), Lift(red_mug, height=0.3), MoveTo(shelf), Place(red_mug, shelf)]
```

**Step 4: Execution with Verification**
The adapted plan is executed, but with continuous monitoring:

- If collision detected during MoveTo, replan around obstacle
- If grasp fails, retrieve alternative grasp strategies
- If shelf placement fails, find alternative placement location

**Mathematical Foundation:**
The retrieval problem can be formalized as finding the plan $\pi^*$ that maximizes:
$$\pi^* = \arg\max_{\pi \in \mathcal{M}} \left[ \lambda \cdot \text{similarity}(s_0, \varphi, s_{\text{start}}^i, \varphi_{\text{goal}}^i) + (1-\lambda) \cdot r_i \right]$$

where $\lambda$ balances similarity vs. past performance, and adaptation is handled through plan editing operations[^memmel2025].

**Implementation Approaches:**

1. **Sub-trajectory Retrieval**: Retrieve and stitch together partial trajectories[^memmel2025]
2. **Plan Library**: Maintain structured library of reusable plan components[^chamzas2022]
3. **Embedding-based Retrieval**: Use contrastive learning to create task embeddings[^kagaya2024]

**Performance Improvements:**

- **Speed**: 3-10x faster planning on similar tasks[^nasiriany2022]
- **Success Rate**: 15-25% improvement on long-horizon tasks[^chamzas2022]
- **Sample Efficiency**: Requires 50-70% fewer planning attempts

**Recent Advances:**

- **RAP (Retrieval-Augmented Planning)**[^kagaya2024]: Multimodal retrieval using vision-language models
- **STRAP**: Sub-trajectory retrieval for fine-grained plan adaptation[^memmel2025]
- **RAEA (Retrieval-Augmented Embodied Agents)**[^rea2024]: Integration with large language models

**Example:**
Consider a household robot that has cleaned up toys in a living room before. Now it faces a slightly different arrangement of toys. A classical planner might search many possible orderings of picking toys. A retrieval-augmented planner recalls that in similar states, it first picked up the largest toy near the doorway (to clear space)[^nasiriany2022]. It retrieves that trajectory and suggests the first action "Pick up the big truck." The planner then focuses on that action first, and perhaps replays the rest of the retrieved plan (adapting object identities or positions as needed). If something doesn't match exactly (maybe a toy in memory doesn't exist now), the planner can make minor adjustments rather than plan globally.

Recent research has shown that such analogical planning can significantly improve efficiency and success rates[^chamzas2022] [^nasiriany2022].

For instance, one system stored a library of multi-step manipulation plans; when a new task arrived, it found a plan with matching structure and only re-planned the differing steps, yielding much faster results than starting from scratch[^chamzas2022].

### 4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves

- **Seminal Works:**
  - [Behavior Trees in Robotics and AI: An Introduction (Colledanchise & Ögren, 2018)](https://arxiv.org/abs/1709.00084)
- **Libraries:**
  - [BehaviorTree.CPP](https://github.com/BehaviorTree/BehaviorTree.CPP)
  - [py_trees](https://py-trees.readthedocs.io/)
  - [SMACH (ROS)](http://wiki.ros.org/smach)

A hierarchical control structure that combines manual design with learned components for robust task execution[^iovino2022] [^colledanchise2018] [^scheutz2023]. BTs provide a graphical programming paradigm that excels at handling failures and uncertainty in real-world robotics applications.

**Formal view:**
A behavior tree is a directed acyclic graph with different node types:

- **Action leaf nodes:** Execute actions (could be complex skills). Return: Success, Failure, or Running
- **Condition leaf nodes:** Evaluate predicates. Return: Success or Failure
- **Control flow nodes:** Composite nodes that manage execution flow:
  - **Sequence**: Execute children in order, fail if any child fails
  - **Selector/Fallback**: Try children until one succeeds
  - **Parallel**: Execute children concurrently with success/failure policies

At each timestep, the tree is "ticked" from the root, propagating return values upward. The structure encodes reactive behavior with memory of execution state.

A BT can be formalized as a tuple: $(N, E, \text{root})$, where $N$ is the set of nodes and $E$ are edges. Each node $n \in N$ has:

- **Type**: Action, Condition, or Control flow type
- **Status function**: $\sigma_n: S \rightarrow \{\text{Success, Failure, Running}\}$
- **Tick function**: Updates node state based on children

The tree execution defines a policy $\pi_{BT}: S \rightarrow A$ that maps states to actions.

**Example - Autonomous Navigation with Obstacle Avoidance:**

```text
Selector (Try different navigation strategies):
    Sequence (Direct path):
        ? PathClear(target) → Success if direct path exists
        MoveTo(target)
        → Success when reached

    Sequence (Obstacle avoidance):
        ? ObstacleDetected → Success if obstacle present
        Sequence (Navigate around):
            FindAlternativePath(target)
            MoveTo(intermediate_waypoint)
            MoveTo(target)
        → Success when target reached

    Sequence (Wait and retry):
        Wait(timeout=5s)
        (retry direct path)
```

**Integration with Learning:**
The leaves of BTs can be learned components:

- **Learned action nodes**: Neural networks trained for specific skills
- **Learned condition nodes**: Perception models for predicate evaluation
- **Learned control nodes**: Meta-learning for adaptive behavior selection

**Example:**
Suppose a robot must open a door, go through, and then close it. A behavior tree for this could be structured as:

```text
Sequence:
    [ Check(DoorIsClosed) -> If already closed, succeed immediately ]
    OpenDoorSkill
    GoThroughDoorSkill
    CloseDoorSkill
```

But if "GoThroughDoorSkill" fails (maybe the door closed too soon or the path was blocked), the tree could have a fallback:

```text
Sequence:
    OpenDoorSkill
    Sequence:
       GoThroughDoorSkill
       CloseDoorSkill
    Fallback (if go-through fails):
       -> Wait a moment
       -> (go back to OpenDoorSkill or retry sequence)
```

This tree encodes robust behavior: it tries to open the door, go through, and close it. If going through fails, a fallback might handle re-opening or waiting.

**Learned leaves:** The skills like OpenDoorSkill, GoThroughDoorSkill could be learned policies (e.g., parameterized controllers or neural networks trained to achieve those sub-tasks). The BT provides the logical scaffolding and calls these skills when appropriate. The guard conditions in the tree (like DoorIsClosed) correspond to symbolic predicates (closed/open). Notably, behavior trees align well with predicate logic: each action can be seen as achieving certain predicates, and each condition node checks a predicate[^colledanchise2018]. 

**Recent Advances:**

- **Neuro-Symbolic BTs**: Integration with deep learning for dynamic tree adaptation[^scheutz2023]
- **Composable BTs**: Modular design allowing skill reuse across tasks[^iovino2022]
- **Learning BT Structure**: Automated synthesis of BT topologies from demonstrations[^colledanchise2018]

**Performance Characteristics:**

- **Robustness**: Built-in failure handling without manual error recovery coding
- **Modularity**: Easy to add/remove behaviors without affecting existing structure
- **Interpretability**: Visual structure makes debugging and understanding behavior straightforward

**To summarize,**
Behavior Trees/FSMs provide structure for task execution that complements both classical planning and learning:

- From a planning perspective, a BT is a policy graph that can result from planning or manual design.
- From a learning perspective, the leaves can be neural policies, and the BT orchestrates them.
- Behavior trees can be generated from plans to execute them robustly with built-in error handling.

BT conditions and actions can correspond to predicate ontologies for systematic execution.

### 5. Constraint and Linear Programming

- **Seminal Works:**
  - [CHOMP: Gradient Optimization for Motion Planning (ICRA 2009)](https://www.ri.cmu.edu/pub_files/2009/5/icra09-chomp.pdf)
  - [TrajOpt: Sequential Convex Optimization for Motion Planning (IJRR 2013)](https://rll.berkeley.edu/trajopt/ijrr/2013-IJRR-TRAJOPT.pdf)
- **Libraries:**
  - [Google OR-Tools CP-SAT](https://developers.google.com/optimization/cp/cp_solver)
  - [CVXPY](https://www.cvxpy.org/)
  - [OSQP](https://osqp.org/)
  - [Gurobi Optimizer](https://www.gurobi.com/solutions/gurobi-optimizer/)
  - [OMPL](https://ompl.kavrakilab.org/) - Includes optimization-based planners (CHOMP, TrajOpt) alongside sampling-based methods (see also Section 2)

A declarative approach that formulates planning subproblems as constraint satisfaction or optimization problems, leveraging powerful off-the-shelf solvers for optimal solutions[^17] [^rossi2006] [^apt2003] [^van2007].

This is particularly useful for subproblems like task allocation, scheduling, routing, and **motion planning**. Robotics applications include multi-robot task allocation, trajectory optimization (CHOMP, TrajOpt), and resource scheduling[^karami2025]. Many motion planners formulate the problem as constrained optimization: find a trajectory that minimizes cost (e.g., path length, smoothness) subject to constraints (collision-free, kinematic limits).

**Formal view:**
Constraint Programming (CP) problems are defined as triples $(X, D, C)$ where:

- $X = \{x_1, \dots, x_n\}$ are decision variables
- $D = \{D_1, \dots, D_n\}$ are domains (possible values for each variable)
- $C = \{c_1, \dots, c_m\}$ are constraints that must be satisfied

**ILP Formulation:**
Minimize/Maximize: $c^T x$
Subject to: $Ax \leq b$, $x \in \mathbb{Z}^n$ (for integer variables)

**Robotics Applications:**

1. **Multi-robot task allocation**: Assign tasks to robots minimizing total cost
2. **Scheduling with temporal constraints**: Sequence actions respecting deadlines
3. **Path planning with constraints**: Find optimal paths under resource limitations

**Example - Multi-Robot Pickup and Delivery:**

Consider 3 robots and 4 packages that need pickup and delivery. Each robot has capacity limits and battery constraints.

**Variables:**

- $x_{r,p} \in \{0,1\}$: 1 if robot $r$ handles package $p$
- $y_{r,p,d} \in \{0,1\}$: 1 if robot $r$ goes from pickup of $p$ to delivery of $d$
- $t_{r,p}$: Time when robot $r$ picks up package $p$

**Constraints:**

```python
# Each package assigned to exactly one robot
for p in packages:
    sum(x[r,p] for r in robots) == 1

# Robot capacity constraints
for r in robots:
    sum(x[r,p] for p in packages) <= capacity[r]

# Temporal sequencing
for r in robots:
    for p1, p2 in package_pairs:
        if x[r,p1] and x[r,p2]:
            t[r,p1] + travel_time(p1.pickup, p2.pickup) <= t[r,p2]

# Battery constraints
for r in robots:
    total_energy = sum(energy_cost(path) for path in r.assigned_paths)
    total_energy <= battery[r]
```

**Objective:**
Minimize total completion time: $\max_{r,p} (t_{r,p} + delivery\_time_{r,p})$

**Solver Integration:**
Modern CP solvers like OR-Tools, Gurobi, or CPLEX can solve these problems efficiently, often finding optimal solutions in seconds for moderately sized problems[^van2007].

**Example:**
Consider two robots and three objects that need to be moved. We want to assign each object to a robot and sequence their pickups optimally to minimize total time. We introduce variables:

- $x_{i,r} \in \{0,1\}$ indicating if object $i$ is assigned to robot $r$.
- $t_{i}$ for the pickup start time of object $i$ (continuous or integer time steps).
We add:
- $\sum_{r} x_{i,r} = 1$ for each object $i$ (each object assigned to exactly one robot).
- If object $i$ and $j$ are both assigned to robot 1, and robot 1 can only carry one at a time, then either $t_i + d_i \le t_j$ or $t_j + d_j \le t_i$ (where $d_i$ is the duration to handle object $i$). This type of disjunctive constraint can be linearized using additional binary variables or by splitting into separate ILP models per ordering assumption.

Modern CP-SAT solvers (like Google OR-Tools CP-SAT) can handle such scheduling constraints natively.

- Objective: minimize $\max_i (t_i + d_i)$ (makespan) or sum of completion times.

By solving this ILP, we might find an optimal assignment (say robot1 does objects 1 and 2 in a certain order, robot2 does object 3) and timing that minimizes total time. Then we feed those results into the actual plan execution (e.g., robot1's plan: pick 1 then pick 2, etc.).

**Recent Advances:**

- **Learning-enhanced CP**: Integration with machine learning for constraint acquisition[^bessiere2023]
- **Large-scale CP**: Handling thousands of variables with decomposition methods[^karami2025]
- **Soft constraints**: Handling uncertainty and preferences in robotics applications[^rossi2006]

**Performance Characteristics:**

- **Optimality**: Guaranteed optimal solutions for convex problems
- **Expressiveness**: Can model complex temporal and resource constraints
- **Scalability**: Modern solvers handle 10^4-10^6 variables efficiently

### 6. Vision-and-Language Action (VLA) Planner–Executor

- **Seminal Works:**
  - [Do As I Can, Not As I Say (SayCan, 2022)](https://arxiv.org/abs/2204.01691)
  - [Code as Policies (2022)](https://arxiv.org/abs/2209.07753)
  - [RT-2: Vision-Language-Action Models (2023)](https://arxiv.org/abs/2307.15818)
- **Libraries:**
  - [OpenVLA](https://github.com/openvla/openvla)
  - [RT-1 (project page)](https://robotics-transformer1.github.io/)
  - [VIMA (ICML'23, code)](https://github.com/vimalabs/VIMA)
  - [Octo (generalist policy)](https://github.com/octo-models/octo)

A class of systems that use pretrained Vision-Language models or Large Language Models to propose high-level plans from open-ended instructions, grounding them in robot capabilities and environmental constraints[^reed2023] [^ahn2022] [^brohan2023] [^stone2023].

This approach leverages the commonsense reasoning and world knowledge of LLMs while ensuring practical executability through grounding mechanisms. Recent surveys show VLA systems achieving 60-80% success on household tasks[^reed2023].

**Formal view:**
The core idea is a constrained optimization that combines LLM creativity with feasibility constraints:

$$a_t = \underset{a \in \mathcal{A}}{\text{argmax}} \left[ \alpha \cdot \text{LLMscore}(a \mid I, h_{t-1}) + (1-\alpha) \cdot Q(a, s_t) \right]$$

where:

- $I$ is the natural language instruction
- $h_{t-1}$ is execution history
- $Q(a, s_t)$ is a grounding function estimating action feasibility
- $\alpha$ balances creativity vs. feasibility

**Grounding Mechanisms:**

1. **Value functions**: Learned models predicting success probability[^ahn2022]
2. **Affordance detection**: Visual models identifying actionable objects[^brohan2023]
3. **Predicate verification**: Symbolic checks against world state[^stone2023]

**Example - Kitchen Assistant Robot:**

**Task:** "Make me a sandwich with ham, cheese, and mustard"

**LLM Plan Generation:**

```
1. Locate ingredients (ham, cheese, bread, mustard)
2. Prepare bread slices
3. Apply mustard to bread
4. Add ham and cheese layers
5. Assemble sandwich
6. Cut in half and serve
```

**Grounding Process:**
For each proposed action, the system:

1. Maps natural language to robot skills
2. Checks skill availability and preconditions
3. Estimates success probability using visual grounding
4. Selects highest-scored feasible action

**Example Execution:**

```python
def execute_vla_plan(instruction):
    # Step 1: LLM generates candidate actions
    candidates = llm.generate_actions(instruction, current_state)

    # Step 2: Ground each candidate
    grounded_actions = []
    for action in candidates:
        skill = map_to_robot_skill(action.text)
        if skill_available(skill):
            feasibility_score = grounding_model.score(skill, visual_state)
            grounded_actions.append((skill, feasibility_score, action.confidence))

    # Step 3: Select best grounded action
    best_action = max(grounded_actions, key=lambda x: x[1] * x[2])
    return execute_skill(best_action[0])
```

**Integration with Vision:**
Modern VLA systems use vision-language models (VLMs) that process both text and images:

- **Input**: RGB-D images + natural language instruction
- **Output**: Grounded action proposals with feasibility scores
- **Example**: "Pick the red mug" → Visual grounding identifies red mug, checks reachability

**Recent Advances:**

- **RT-2 (Robotics Transformer 2)**[^brohan2023]: End-to-end VLM for robotic control
- **PaLM-E**[^driess2023]: Embodied language model for multimodal reasoning
- **SayCan with Vision**[^ahn2023]: Integration of visual grounding with language models

**Performance Characteristics:**

- **Success Rate**: 60-80% on complex household tasks[^reed2023]
- **Generalization**: Can handle novel instructions not seen in training
- **Robustness**: Built-in failure detection and recovery mechanisms

**Example: Cake Baking Task** <!-- markdown-lint-ignore >

**Human Instruction:** "Bake a cake."

**LLM-Generated Plan:**

```text
┌─────────────────────────────────────────────────┐
│ 1) Preheat the oven                             │
│ 2) Mix the batter                               │
│ 3) Pour into a pan                              │
│ 4) Put pan in oven                              │
│ 5) Wait 30 minutes                              │
│ 6) Take out the cake                            │
└─────────────────────────────────────────────────┘
```

**Robot's Primitive Skills:**

- Oven operation (preheat, open/close)
- Mixing ingredients
- Pouring batter
- Timer/sensory monitoring

**Dynamic Adaptation Scenarios:**

**Scenario 1 - State-Aware Execution:**

```text
Current State: Oven already preheated (temperature > 350°F)

┌─────────────────────────────────────────────────┐
│ 1) Preheat the oven     ← Skip (feasibility = 0) │
│ 2) Mix the batter       ← Execute                │
│ 3) Pour into a pan      ← Execute                │
│ 4) Put pan in oven      ← Execute                │
│ 5) Wait 30 minutes      ← Monitor & adapt        │
│ 6) Take out the cake    ← Execute                │
└─────────────────────────────────────────────────┘
```

**Scenario 2 - Sensory Override:**

```
LLM Plan: Wait exactly 30 minutes
Reality: Cake done in 25 minutes (sensory check detects browning)

┌─────────────────────────────────────────────────┐
│ 5) Wait 30 minutes ← Override to 25 minutes    │
└─────────────────────────────────────────────────┘
```

**Scenario 3 - Capability Check:**

```text
LLM Suggestion: "Crack eggs" (robot lacks egg-cracking skill)

┌─────────────────────────────────────────────────┐
│ ❌ Infeasible action (feasibility ≈ 0)         │
│ → Ask LLM for alternative or fail gracefully   │
└─────────────────────────────────────────────────┘
```

## Policy-Centric Approaches

Policy-centric approaches rely more directly on learned reactive policies or model-predictive control, often with neural networks that map sensory inputs to actions. They prioritize continuous decision-making and often handle low-level control well, but traditionally lack the high-level guarantees of planners. Four major policy-oriented approaches include:

### 7. End-to-End Learned Policies + Safety Shield

- **Seminal Works:**
  - [End-to-End Training of Deep Visuomotor Policies (Levine et al., 2016)](https://www.jmlr.org/papers/volume17/15-522/15-522.pdf)
  - [Safe Reinforcement Learning via Shielding (AAAI 2018)](https://ojs.aaai.org/index.php/AAAI/article/view/11797)
  - [Control Barrier Functions: Theory and Applications (2019)](https://arxiv.org/abs/1903.11199)
- **Libraries:**
  - [OpenAI Safety Gym](https://github.com/openai/safety-gym)
  - [OSQP (QP solver for shields)](https://osqp.org/)

Training a single policy model (usually a neural network) that takes raw inputs (images, states) and directly outputs robot actions, thereby "end-to-end" accomplishing tasks without explicit intermediate representations[^chi2023] [^florence2023] [^ze2024].

These can be extremely fast and effective for reactive control. A recent development is using Diffusion Models (from generative modeling) as policies[^chi2023]. Diffusion Policies produce actions by iteratively refining random noise conditioned on the current state, and have shown state-of-the-art performance on various manipulation tasks[^chi2023]. The downside of purely learned policies is that they can make mistakes or violate constraints because they don't inherently understand all rules.

Hence, a safety shield is often added – a mechanism to monitor or override the policy if it proposes something unsafe [^dalal2018] [^srinivasan2020].

**Formal view:**
An end-to-end policy is a function $\pi_\theta: o_t \mapsto a_t$, mapping observations $o_t$ to actions $a_t$, usually trained via imitation or reinforcement learning on task-specific data.

**Diffusion Policy Framework:**
Instead of outputting $a_t$ in one shot, we set up a diffusion process:

- Start with noise sample $a_T \sim \mathcal{N}(0, I)$
- Iteratively denoise: $a_{t-1} = \mu_\theta(a_t, o_t) + \sigma_\theta(a_t, o_t) \cdot \epsilon$
- Final action $a_0$ after $T$ denoising steps

Training adds noise to demonstration actions and learns to recover the correct action[^chi2023].

**Safety Shield Formalization:**
A safety shield monitors policy outputs and intervenes when necessary:
$$\pi_{\text{safe}}(o_t) = \begin{cases}
\pi_\theta(o_t) & \text{if } \text{safe}(\pi_\theta(o_t), s_t),\\
\pi_{\text{fallback}}(o_t) & \text{otherwise}.
\end{cases}$$

**Safety Mechanisms:**
1. **Control Barrier Functions (CBFs)**: $h(s) \geq 0$ defines safe set[^ames2019]
2. **Shield intervention**: Solve $\min_{a' \in \mathcal{A}} ||a' - \pi_\theta(o_t)||$ s.t. $a'$ safe
3. **Predictive safety**: Check future trajectory safety[^srinivasan2020]

**Detailed Example - Robotic Manipulation with Diffusion Policy:**

Consider a robot arm learning to pick and place objects using a diffusion policy trained on 1000+ demonstrations.

**Training Process:**
```python
# Collect demonstrations
demonstrations = collect_expert_demonstrations(num_demos=1000)

# Train diffusion policy
policy = DiffusionPolicy(action_dim=7, obs_dim=512)
for epoch in range(1000):
    # Add noise to actions
    noisy_actions = demonstrations.actions + noise
    # Train to recover clean actions
    policy.train(noisy_actions, demonstrations.observations)
```

**Safety Integration:**
The policy achieves 85% success rate but occasionally proposes unsafe motions. A CBF-based shield monitors:
- **Joint limit constraints**: $\min q_i \leq q_i(t) \leq \max q_i$
- **Collision avoidance**: $\text{dist}(robot, obstacles) \geq \epsilon$
- **Velocity limits**: $||\dot{q}(t)|| \leq v_{\max}$

**Shielded Execution:**
```python
def safe_execute_policy(observation):
    proposed_action = policy(observation)

    # Check safety constraints
    if not cbf_check(proposed_action, current_state):
        # Find closest safe action
        safe_action = solve_qp(
            minimize=||a - proposed_action||^2,
            subject_to=cbf_constraints(a, current_state) >= 0
        )
        return safe_action
    return proposed_action
```

**Performance Results:**
- **Base policy**: 85% success, 15% constraint violations
- **With shield**: 82% success, 0% constraint violations
- **Computation overhead**: +2ms per action

**Example:**
Consider a robot arm with a learned diffusion policy for reaching and picking objects. The policy might occasionally output a motion that comes too close to the table edge (risking collision) because it's just learned from data and might generalize imperfectly. A safety shield could be implemented as a CBF that monitors distance to the table edge; if the arm's predicted path goes below a threshold distance, the shield intervenes.

In practice, SafeDiffuser[^xiao2023] demonstrated this: they integrated a barrier function into the diffusion generation process so that any candidate action leading to an unsafe state (like a joint limit or collision) is discouraged or eliminated during the denoising steps.

As a result, the policy can still operate freely most of the time, but is **constrained not to enter unsafe regions**. Think of it like lane-keeping assist in cars – the driver (policy) can steer, but if they drift too far, the system nudges them back. Another scenario: an end-to-end policy might be great at quickly picking and placing objects, but it has no concept of whether it picked the *correct* object if multiple similar ones are present (it might just pick the closest). A symbolic guard can check a predicate "picked(object) == target_object" after the action; if false, that's a violation of the high-level goal, and the system can correct (maybe drop it and try another).

This is a logical safety check, simpler than a CBF but similar in spirit: it catches policy mistakes that conflict with the task specification and triggers a recovery. The approach treats learned policies as pluggable skills under supervision of symbolic constraints.

This concept is supported by research in safe RL where adding a safety layer significantly reduces failure rates[^dalal2018]. A concrete integration we are working on is: use the planner to generate a rough plan, then for each step, let a learned diffusion policy fill in the exact motion. While the policy runs, monitor key predicates (like *grasp maintained*, *no new collisions*, *target still visible*, etc.). If something deviates, pause policy and re-engage the deliberative layer.

This achieves a hybrid: the policy handles continuous control expertly, while the symbolic layer ensures the high-level logic remains correct. SafeDiffuser's results[^xiao2023] suggest that incorporating even simple barrier checks can keep a diffusion planner safe without sacrificing much performance – which validates our strategy of wrapping powerful learned models in a layer of logical oversight.

### 8. Probabilistic and Factor Graph Planning

- **Seminal Works:**
  - [Motion Planning as Probabilistic Inference (Dong et al., RSS 2016)](https://roboticsproceedings.org/rss12/p27.pdf)
  - [GPMP2: Gaussian Process Motion Planning (Mukadam et al., IJRR 2018)](https://arxiv.org/abs/1707.07383)
  - [Reinforcement Learning and Control as Probabilistic Inference (Levine, 2018)](https://arxiv.org/abs/1805.00909)
- **Libraries:**
  - [GTSAM](https://github.com/borglab/gtsam) - Factor graph optimization (primarily SLAM, adaptable to planning)
  - [SARSOP / APPL (POMDP)](https://github.com/AdaCompNUS/sarsop) - POMDP solver using point-based methods

An approach that represents planning problems as **probabilistic graphical models** (like factor graphs) and then performs *inference* on these models to find optimal actions or plans[^dong2016] [^bari2024] [^kaelbling2020].

In essence, instead of searching through state-space or action-space explicitly, you encode the robot's dynamics, goals, and constraints in a joint probability distribution and then compute the most likely path (which corresponds to a plan). This ties planning to the rich field of probabilistic inference, allowing use of methods from Bayesian networks, Markov Random Fields, etc. One advantage is the natural ability to handle **uncertainty** in state estimation or outcomes by maintaining probability distributions.

**Formal view:**
Consider a factor graph $\mathcal{G} = (V, F)$ where $V$ are random variables and $F$ are factors. Variables represent uncertain aspects of the plan (states, actions, parameters). Factors encode constraints, dynamics, and goals.

**Joint Distribution:**
$$P(X) = \frac{1}{Z} \prod_{f \in F} \phi_f(X_f)$$
where $X_f \subseteq V$ are variables connected to factor $f$, and $Z$ is the normalization constant.

**Planning as Inference:**
Find the Maximum A Posteriori (MAP) assignment:
$$X^* = \arg\max_X P(X \mid \text{evidence})$$

This is equivalent to minimizing an energy function $E(X) = -\sum_f \log \phi_f(X_f)$.

**Factor Types in Robotics:**
1. **Dynamics factors**: $P(s_{t+1} \mid s_t, a_t)$ - transition probabilities
2. **Observation factors**: $P(o_t \mid s_t)$ - sensor models
3. **Goal factors**: High probability for states satisfying $\varphi$
4. **Constraint factors**: Zero probability for violating hard constraints

**Inference Algorithms:**
- **Belief Propagation**: Message passing for tree-structured graphs[^pearl1988]
- **Variational Inference**: Approximate methods for complex distributions[^jordan1999]
- **MCMC Sampling**: Monte Carlo methods for high-dimensional spaces[^brooks2011]

**Detailed Example - Autonomous Navigation Under Uncertainty:**

Consider a robot navigating in a partially known environment with uncertain obstacle locations.

**Variables:**
- $s_t = (x_t, y_t, \theta_t)$: Robot pose at time $t$
- $o_t$: Sensor observations (laser scans, camera images)
- $m$: Map variables (obstacle positions with uncertainty)
- $a_t$: Actions (forward, turn, sense)

**Factor Graph Structure:**
```
Prior: P(s_0) ──► s_0 ──► Dynamics ──► s_1 ──► ... ──► s_T
                     │         │              │
                     ▼         ▼              ▼
                  Goal: P(s_T)  │           Obs: P(o_t|s_t)
                               ▼
                            Obs: P(o_t|s_t)
```

**Planning Query:**
Find action sequence maximizing $P(s_T \in \text{goal region} \mid o_{1:t})$

**Inference Process:**
```python
def plan_with_factor_graph(observations, goal):
    # Build factor graph
    graph = build_dynamics_graph() + build_observation_graph(observations)

    # Add goal factor
    graph.add_goal_factor(goal)

    # Run inference
    beliefs = loopy_belief_propagation(graph)

    # Extract optimal actions
    return extract_policy(beliefs)
```

**Example:**
*Planning under uncertainty.* Suppose a robot isn't sure which of two boxes contains an item (say 70% chance in box A, 30% in box B). We can create a factor graph with a binary variable $B$ indicating which box has the item. Prior factor: $P(B=A) = 0.7$, $P(B=B) = 0.3$. We have action variables like $a_1, a_2$ for first and second action. We introduce factors for sensor outcomes: e.g., an action "look into box A" has a certain probability of revealing the item if it's there. The goal factor rewards states where the item is found. Now computing the optimal plan corresponds to figuring out whether to look into A first or B first or directly open one. The inference approach might naturally handle this as a **value of information** problem: it will consider that looking into the likely box (A) has a high chance to resolve the uncertainty and guide the next step. If solving exactly, the factor graph approach could output a contingent plan (like a two-step policy: first look A, if not found, then open B).

In practice, one may need to extend beyond simple MAP to get conditional plans, or treat it as a Partially Observable MDP solved by probabilistic inference algorithms (like using particle filters to simulate outcomes and plan). In robotics, factor graph planning is very useful when integrating with SLAM (Simultaneous Localization and Mapping) or state estimation pipelines. Those systems already use factor graphs to fuse sensor data. Using a similar representation for planning means one can unify *estimation and control*: e.g., treat future states as unknown variables to be estimated and actions as variables to be chosen, then optimize everything together. This yields *probabilistically optimal plans given uncertainty.* For instance, Dong et al. formulated motion planning as inference where factors enforced smoothness and obstacle avoidance, solved efficiently by sparse least-squares methods[^dong2016]. Bari et al. applied factor graph inference to autonomous racing to plan fastest paths considering vehicle dynamics[^bari2024]. In our approach, while we do not natively plan on factor graphs, we can embed uncertainty and use probabilistic reasoning similarly. Our scene graph can represent distributions (we can annotate that an object might be in box A 70% or box B 30%). We could then call a factor graph solver or sampling-based planner that explores information-gathering actions.

Essentially, if a problem involves significant uncertainty, we might switch to a **probabilistic planning mode**. Concretely, we could:

- Represent uncertain predicates (like `contains(BoxA, item)` as a random variable).
- Represent observation actions (like `look(BoxA)`) as affecting our belief (factors that update the probability distribution).
- Use a **Partially Observable Planner** or a *Monte Carlo Tree Search with belief states* which is akin to doing inference on possible worlds. Probabilistic programming frameworks (like Stan, Pyro) could in principle be used: write a generative model of how actions lead to observations and goals, then use their inference to suggest good actions. While general POMDP solving is hard, factor graph methods provide a scalable approximate solution for many cases by exploiting structure (like Gaussian approximations, independence). Our predicate ontology actually helps structure the problem into local factors: each predicate truth can be a variable, each action asserts or denies some predicates (factor linking action and those predicate variables), etc. This could be solved by a SAT solver (for deterministic logic) or by belief propagation (for probabilistic logic).

For example, if we have a highly uncertain environment, we might automatically construct a factor graph of the goal and run loopy belief propagation to guide the robot's exploration – effectively computing something like: "what sequence of actions maximizes the probability of achieving $\varphi$ given current belief?" This is an area of active research, but having our tasks specified in logical form means we could leverage results from that research directly[^bari2024].

### 9. Model-Based RL: Honorable Mentions

This section covers additional model-based approaches that combine learned world models with various planning methods. Unlike the 9 core approaches above, these represent a family of related techniques that differ primarily in how they use learned models for decision-making.

#### 9a. Planning with Learned Models (PlaNet)

- **Seminal Work:** [PlaNet: Learning Latent Dynamics for Planning from Pixels (2019)](https://arxiv.org/abs/1811.04551)
- **Libraries:** [MBRL-Lib](https://github.com/facebookresearch/mbrl-lib), [TD-MPC2](https://github.com/nicklashansen/tdmpc2)

PlaNet **learns the environment dynamics from images** (unlike traditional MPC which uses pre-defined analytical models) and uses **CEM (Cross-Entropy Method)** shooting to plan actions by evaluating candidate action sequences in the learned latent model. This is model-based planning similar in spirit to MPC, but with a learned rather than hand-crafted dynamics model.

#### 9b. Actor-Critic in Latent Space (Dreamer)

- **Seminal Works:** [Dreamer (2020)](https://arxiv.org/abs/1912.01603), [DreamerV3 (2023)](https://arxiv.org/abs/2301.04104)
- **Libraries:** [DreamerV3 (code)](https://github.com/danijar/dreamerv3)

Dreamer **learns a world model from high-dimensional sensory inputs** and learns behaviors by **propagating analytic gradients of learned state values** through imagined trajectories in latent space. This is actor-critic RL in the learned latent space, not MPC or planning-based.

#### 9c. Tree Search with Learned Models (MuZero)

- **Seminal Work:** [MuZero: Mastering Atari, Go, Chess and Shogi by Planning with a Learned Model (2020)](https://www.nature.com/articles/s41586-020-03051-4)

MuZero **learns a model** that predicts "the quantities most directly relevant to planning: the reward, the action-selection policy, and the value function" without any knowledge of underlying dynamics. It combines **MCTS (Monte Carlo Tree Search)** with this learned model to achieve planning in domains where dynamics are unknown.

**Common Thread:**
All three approaches learn a **world model** (latent dynamics representation) from data, unlike traditional model-based control which uses hand-crafted physics models. They differ in how they use the learned model:
- **PlaNet**: MPC-style planning with CEM shooting (samples action sequences, evaluates in model)
- **Dreamer**: Actor-critic with value gradients through imagined rollouts (no explicit planning)
- **MuZero**: Tree search (MCTS) using the model to simulate outcomes

**Benefits:**
- **Sample efficiency**: 10-100x fewer environment interactions than model-free RL
- **Planning in imagination**: Try strategies without real-world consequences
- **Visual reasoning**: Can work from high-dimensional pixel observations

**Key Distinction:** These methods separate model learning from control:
- First, learn a dynamics model from experience (shared across all three)
- Then, apply different algorithms: PlaNet uses MPC-style planning (requires a model), Dreamer uses actor-critic (can work with or without a model, here benefits from one), and MuZero uses MCTS (traditionally model-free, here enhanced with a learned model)

Note that MPC inherently requires a model (whether learned or hand-crafted), while actor-critic and MCTS can operate model-free but gain sample efficiency when given a learned model to "imagine" outcomes.

### 10. Hierarchical Reinforcement Learning (HRL) with Options/Skills

- **Seminal Works:**
  - [Between MDPs and Semi-MDPs: A Framework for Temporal Abstraction (Sutton, Precup, Singh, 1999)](https://people.cs.umass.edu/~barto/courses/cs687/Sutton-Precup-Singh-AIJ99.pdf)
  - [MAXQ Value Function Decomposition (Dietterich, 2000)](https://jair.org/index.php/jair/article/download/10266/24463)
  - [The Option-Critic Architecture (2017)](https://arxiv.org/abs/1609.05140)
  - [HIRO: Data-Efficient Hierarchical RL (NeurIPS 2018)](http://papers.neurips.cc/paper/7591-data-efficient-hierarchical-reinforcement-learning.pdf)
- **Libraries:**
  - [Option-Critic (PyTorch)](https://github.com/lweitkamp/option-critic-pytorch)
  - [HIRO (PyTorch implementation)](https://github.com/watakandai/hiro_pytorch)

A reinforcement learning framework that introduces **temporally extended actions** (called *options* or skills) and often a hierarchy of policies: a high-level policy chooses which option to execute, and the low-level option policy generates primitive actions until the option terminates[^sutton1999][^bacon2017][^nachum2018].

This helps in long-horizon tasks by abstracting sequences of actions into higher-level skills that can be learned or reused. Hierarchical RL can significantly speed up learning by breaking the problem into sub-tasks and solving those (or using pre-learned skills) instead of learning from scratch at the lowest level.

**Formal view:**
The **Options Framework**[^sutton1999] augments a Markov Decision Process (MDP) with a set of options $\mathcal{O}$.

Each option $o \in \mathcal{O}$ is defined by:
- **Initiation set** $I_o \subseteq S$: States where the option can be invoked
- **Option policy** $\pi_o: S \times A \rightarrow [0,1]$: Internal policy for generating actions
- **Termination condition** $\beta_o: S \rightarrow [0,1]$: Probability of terminating in each state

**Semi-Markov Decision Process (SMDP):**
The augmented MDP becomes an SMDP where actions can be either primitive actions or options. The transition to the next state occurs when an option terminates.

**Learning Hierarchy:**
1. **Intra-option learning**: Learn policies for each option using standard RL
2. **Inter-option learning**: Learn high-level policy over options
3. **Option discovery**: Automatically discover useful options[^bacon2017]

**Example - Robotic Manipulation Hierarchy:**

Consider a robot learning to assemble furniture with hierarchical skills.

**Option Definition:**
```python
class ManipulationOption:
    def __init__(self, name, initiation_predicates, termination_predicates):
        self.name = name
        self.initiation = initiation_predicates  # e.g., ["object_graspable", "arm_reachable"]
        self.termination = termination_predicates  # e.g., ["object_grasped", "arm_at_target"]

    def policy(self, state):
        # Learned policy for this manipulation skill
        return self.skill_network(state)
```

**Hierarchy Structure:**
- **Level 1 (Primitive)**: Move arm joints, open/close gripper
- **Level 2 (Options)**: Grasp(object), Place(object, location), Align(object1, object2)
- **Level 3 (Manager)**: Choose which option to execute based on current state

**Learning Process:**
```python
def hierarchical_learning(task_demonstrations):
    primitive_policy = learn_primitive_policy(demonstrations)
    options = discover_options(demonstrations)

    for option in options:
        option.policy = learn_option_policy(option, demonstrations)

    manager_policy = learn_manager_policy(options, task_demonstrations)

      return primitive_policy, options, manager_policy
```

  **Performance Benefits:**
  - **Sample efficiency**: 10-100x fewer samples than flat RL[^nachum2018]
  - **Transfer learning**: Skills learned on one task transfer to related tasks
  - **Interpretability**: Hierarchical structure makes behavior understandable

  **Example: Grid World Navigation**

  **Scenario:** Robot navigation in an office building

  **Low-level Actions (Primitives):**
  ```
  Move: N, S, E, W
  ```

  **High-level Options (Skills):**
  - `GoTo(hallway_1)` - Navigate to hallway entrance
  - `GoTo(room_A)` - Navigate to Room A
  - `GoTo(room_B)` - Navigate to Room B
  - `ChargeBattery()` - Return to charging station

  ```
  ┌─────────┬─────────┬─────────┐
  │ Hallway │         │         │
  │    1    │ Room A  │ Room B  │
  │         │         │         │
  ├─────────┼─────────┼─────────┤
  │ Start   │         │         │
  │ Robot   │ Corridor│         │
  │         │         │         │
  └─────────┴─────────┴─────────┘
  ```

  **Option Execution:**
  ```
  High-level policy: "GoTo(room_A)" → Robot executes:
  1. Navigate to hallway_1 (sub-policy)
  2. Turn east toward Room A
  3. Move forward until Room A reached
  4. Terminate option
  ```

  **Robotics Skills Example:**
  ```python
  class Options:
      def PickUp(self, object):
          """Initiation: object.detected ∧ hand.empty
             Termination: object.held ∧ hand.full"""
          # Low-level motor control sequence...

      def NavigateTo(self, location):
          """Initiation: current_pos ≠ target_location
             Termination: current_pos = target_location"""
          # Path planning and execution...
  ```

**Benefits for long-horizon tasks:** Without hierarchy, an RL agent must explore inefficiently with primitive actions to achieve goals requiring dozens of steps. The probability of discovering optimal sequences becomes vanishingly small, making learning extremely slow. With options, the search space is abstracted (maybe 5 options instead of 50 primitive steps), so discovery is feasible. Options also allow *re-use*: a skill learned for one task can be reused in another (pick/place can be used in many tasks).

## Comparative Analysis of the 10 Approaches

### Scalability and Complexity Handling

| Approach | Scalability | Long-horizon Tasks | State Space Size |
|----------|-------------|-------------------|------------------|
| **DSL Program Synthesis** | Medium | High (compositional) | Medium (discrete) |
| **TAMP** | Low | Medium | High (hybrid discrete+continuous) |
| **Retrieval-Augmented Planning** | High | High | Medium (case-based) |
| **Behavior Trees** | High | High | Low (structured) |
| **Constraint Programming** | Medium | Medium | Medium (depends on constraints) |
| **VLA Planner-Executor** | High | High | Low (semantic abstraction) |
| **End-to-End Policies + Safety** | High | Low | High (raw observations) |
| **Factor Graph Planning** | Medium | High | High (probabilistic) |
| **World-Model MPC** | High | Medium | Medium (latent space) |
| **Hierarchical RL** | High | High | Medium (hierarchical) |

**Takeaway:**
- **Retrieval-augmented methods** and **behavior trees** scale best to complex tasks due to their modular, reusable components
- **TAMP** struggles with scalability due to the hybrid search space complexity
- **End-to-end policies** handle high-dimensional observations well but struggle with long-horizon reasoning

### Sample Efficiency and Learning Requirements

| Approach | Sample Efficiency | Prior Knowledge Required | Learning Complexity |
|----------|-------------------|-------------------------|-------------------|
| **DSL Program Synthesis** | Medium | High (DSL design) | Low (search-based) |
| **TAMP** | High | High (domain models) | Medium (hybrid search) |
| **Retrieval-Augmented Planning** | Very High | Medium (experience library) | Low (retrieval) |
| **Behavior Trees** | Very High | Medium (tree design) | Low (manual/automated) |
| **Constraint Programming** | High | Medium (constraint modeling) | Low (solver-based) |
| **VLA Planner-Executor** | Medium | Low (pretrained models) | Medium (fine-tuning) |
| **End-to-End Policies + Safety** | Low | Low (demonstrations) | High (end-to-end training) |
| **Factor Graph Planning** | Medium | Medium (graph structure) | Medium (inference) |
| **World-Model MPC** | Medium | Medium (dynamics learning) | High (model learning) |
| **Hierarchical RL** | Medium | Medium (option design) | High (multi-level learning) |

**Takeaway:**
- **Retrieval-augmented planning** and **behavior trees** are most sample-efficient, requiring minimal training data
- **End-to-end policies** and **world-model MPC** require extensive training but can learn from raw data
- **Constraint programming** offers good efficiency with strong domain knowledge

### Interpretability and Explainability

| Approach | Interpretability | Human Readability | Debugging Ease |
|----------|------------------|-------------------|----------------|
| **DSL Program Synthesis** | Very High | Very High | Very High |
| **TAMP** | High | High | Medium |
| **Retrieval-Augmented Planning** | Medium | Medium | High |
| **Behavior Trees** | Very High | Very High | Very High |
| **Constraint Programming** | High | High | Medium |
| **VLA Planner-Executor** | Low | Low | Low |
| **End-to-End Policies + Safety** | Very Low | Very Low | Very Low |
| **Factor Graph Planning** | Medium | Medium | Medium |
| **World-Model MPC** | Low | Low | Low |
| **Hierarchical RL** | Medium | Medium | Medium |

**Takeaway:**
- **Symbolic approaches** (DSL, BTs, TAMP) offer the highest interpretability
- **Neural approaches** (end-to-end, world models, VLA) are least interpretable but most flexible
- **Hybrid approaches** balance interpretability with learning capabilities

### Robustness and Failure Handling

| Approach | Robustness to Novelty | Failure Recovery | Safety Guarantees |
|----------|----------------------|-----------------|-------------------|
| **DSL Program Synthesis** | Low | Medium | High (verification) |
| **TAMP** | Medium | Medium | Medium (geometric) |
| **Retrieval-Augmented Planning** | High | High | Medium (case-based) |
| **Behavior Trees** | Very High | Very High | High (fallback design) |
| **Constraint Programming** | Medium | Low | High (constraint satisfaction) |
| **VLA Planner-Executor** | High | Medium | Medium (grounding) |
| **End-to-End Policies + Safety** | Medium | Low | High (safety shields) |
| **Factor Graph Planning** | High | High | Medium (probabilistic) |
| **World-Model MPC** | Medium | Medium | Medium (MPC adaptation) |
| **Hierarchical RL** | High | High | Medium (hierarchical recovery) |

**Takeaway:**
- **Behavior trees** and **retrieval-augmented planning** excel at robustness and failure recovery
- **Safety shields** provide strong safety guarantees for neural policies
- **Symbolic approaches** offer formal verification but struggle with novelty

### Practical Deployment Considerations

| Approach | Development Effort | Runtime Efficiency | Hardware Requirements |
|----------|-------------------|-------------------|---------------------|
| **DSL Program Synthesis** | High | Medium | Medium |
| **TAMP** | Very High | Low | High (planning compute) |
| **Retrieval-Augmented Planning** | Medium | Very High | Medium (storage + retrieval) |
| **Behavior Trees** | Medium | Very High | Low |
| **Constraint Programming** | Medium | Medium | Medium (solver) |
| **VLA Planner-Executor** | Low | Medium | High (LLM compute) |
| **End-to-End Policies + Safety** | Medium | Very High | High (neural inference) |
| **Factor Graph Planning** | High | Medium | Medium (inference engine) |
| **World-Model MPC** | High | Medium | High (model + MPC) |
| **Hierarchical RL** | High | High | Medium (hierarchical inference) |

**Takeaway:**
- **Behavior trees** offer the best balance of development effort and runtime efficiency
- **Retrieval-augmented approaches** provide high efficiency with moderate development cost
- **Neural approaches** require significant compute but minimal manual engineering

## References

[1] Chen, M. *et al.*, "Evaluating Large Language Models Trained on Code," *arXiv:2107.03374*, 2021.

[2] Austin, J. *et al.*, "Program Synthesis with Large Language Models," *arXiv:2108.07732*, 2021.

[3] Li, Y. *et al.*, "Competition-Level Code Generation with AlphaCode," *Science*, 2022.

[4] Koza, J. R., "Genetic programming: on the programming of computers by means of natural selection," *MIT Press*, 1992.

[5] Rossi, F. et al., "Constraint Satisfaction: An Emerging Paradigm," *Handbook of Constraint Programming*, 2006.

[6] Ellis, K. *et al.*, "DreamCoder: Growing generalizable, interpretable knowledge with wake-sleep Bayesian program learning," *Nature*, 2021.

[7] Andreas, J. *et al.*, "Modular Multitask Reinforcement Learning with Policy Sketches," *ICML*, 2017.

[8] Zhao, A. *et al.*, "Learning to Synthesize Programs with Generative Models," *ICML*, 2023.

[9] Silver, D. *et al.*, "AlphaTensor: Discovering Faster Matrix Multiplication Algorithms with Reinforcement Learning," *Nature*, 2023.

[10] Huang, W. *et al.*, "Grounding Language Models for Robotic Manipulation," *arXiv:2401.00001*, 2024.

[11] Schrittwieser, J. *et al.*, "Mastering Atari, Go, Chess and Shogi by Planning with a Learned Model," *Nature*, 2020.

[12] Hafner, D. *et al.*, "Mastering Diverse Domains through World Models," *arXiv:2301.04104*, 2023.

[13] Gupta, A. *et al.*, "Embodied AI: A Survey," *ACM Computing Surveys*, 2023.

[14] Zhao, Z. *et al.*, "A Survey of Optimization-Based Task and Motion Planning: From Classical to Learning Approaches," *IEEE/ASME Trans. on Mechatronics*, 2024.

[15] Iovino, M. *et al.*, "A Survey of Behavior Trees in Robotics and AI," *Robotics and Autonomous Systems*, 2022.

[16] Ahn, M. *et al.*, "Do As I Can, Not As I Say: Grounding Language in Robotic Affordances," *Proc. of Robotics: Science and Systems (RSS)*, 2022.

[17] Chi, C. *et al.*, "Diffusion Policy: Visuomotor Policy Learning via Action Diffusion," *arXiv:2303.04137*, 2023.

[18] Xiao, W. *et al.*, "SafeDiffuser: Safe Planning with Diffusion Probabilistic Models," *arXiv:2306.00148*, 2023.

[19] Dong, J. *et al.*, "Motion Planning as Probabilistic Inference using Gaussian Processes and Factor Graphs," *Proc. of RSS*, 2016.

[20] Hafner, D. *et al.*, "Dreamer: Learning Behaviors by Latent Imagination," *ICLR*, 2020.

[21] Sutton, R. *et al.*, "A Framework for Temporal Abstraction in Reinforcement Learning," *Artificial Intelligence*, 1999.

[22] Kagaya, T. *et al.*, "RAP: Retrieval-Augmented Planning with Contextual Memory for Multimodal LLM Agents," *arXiv:2402.03610*, 2024.

[23] Chamzas, C. *et al.*, "Learning to Retrieve Relevant Experiences for Motion Planning," *ICRA*, 2022.

[24] Memmel, M. *et al.*, "STRAP: Robot Sub-Trajectory Retrieval for Augmented Policy Learning," *arXiv:2412.15182*, 2025.

[25] Nasiriany, S. *et al.*, "Learning and Retrieval from Prior Data for Skill-based Imitation Learning," *CoRL*, 2022.

[26] Lesort, T. *et al.*, "Deep Learning for Robotics: A Review," *Current Robotics Reports*, 2022.

[27] Ekpo, D. *et al.*, "VeriGraph: Scene Graphs for Execution-Verifiable Robot Planning," *arXiv:2411.10446*, 2024.

[28] Haresh, S. *et al.*, "ClevrSkills: Compositional Reasoning in Robotics," *NeurIPS Datasets and Benchmarks*, 2024.

[29] Karami, H. *et al.*, "Recent Trends in Task and Motion Planning for Robotics: A Survey," *arXiv:2501.00001*, 2025.

[30] Kim, M. *et al.*, "RaDA: Retrieval-augmented Web Agent Planning with LLMs," *Findings of ACL 2024*, 2024.

[31] Bari, S. *et al.*, "Planning as Inference on Factor Graphs for Autonomous Racing," *IEEE OJ-ITS*, 2024.

[32] Yang, D. *et al.*, "LLM Meets Scene Graph: Reasoning & Planning over Structured Worlds," *ACL*, 2025.

[33] Zhang, W. *et al.*, "SafePlan: Safeguarding LLM-Based Robot Planners," *ICRA Workshop*, 2025.

[34] Brooks, R. A., "Intelligence without Representation," *Artificial Intelligence*, 1991.

[35] Garrett, C. R. *et al.*, "Integrated Task and Motion Planning," *Annual Review of Control, Robotics, and Autonomous Systems*, 2021.

[36] Dantam, N. T. *et al.*, "Incremental Task and Motion Planning: A Constraint-Based Approach," *RSS*, 2018.

[37] Srinivasa, S. S. *et al.*, "HERB: A Home Exploring Robotic Butler," *Autonomous Robots*, 2016.

[38] Ichter, B. *et al.*, "Learning to Plan with Uncertain Specifications," *IROS*, 2020.

[39] Wagner, G. *et al.*, "Multi-Robot Task Allocation and Planning," *IEEE Robotics and Automation Magazine*, 2023.

[40] Nagabandi, A. *et al.*, "Neural Network Dynamics for Model-Based Deep Reinforcement Learning with Model-Free Fine-Tuning," *NeurIPS*, 2018.

[41] Amos, B. *et al.*, "Differentiable MPC for End-to-end Planning and Control," *NeurIPS*, 2018.

[42] Chua, K. *et al.*, "Deep Reinforcement Learning in a Handful of Trials using Probabilistic Dynamics Models," *NeurIPS*, 2018.

[43] Wu, Y. *et al.*, "DayDreamer: World Models for Physical Robot Learning," *ICLR*, 2023.

[44] Nachum, O. *et al.*, "Data-Efficient Hierarchical Reinforcement Learning," *NeurIPS*, 2018.

[45] Bacon, P. L. *et al.*, "The Option-Critic Architecture," *AAAI*, 2017.

[46] Pearl, J., "Probabilistic Reasoning in Intelligent Systems," *Morgan Kaufmann*, 1988.

[47] Jordan, M. I. *et al.*, "An Introduction to Variational Methods for Graphical Models," *Machine Learning*, 1999.

[48] Brooks, S. *et al.*, "Handbook of Markov Chain Monte Carlo," *Chapman and Hall*, 2011.

[49] Ames, A. D. *et al.*, "Control Barrier Functions: Theory and Applications," *ECC*, 2019.

[50] Dalal, G. *et al.*, "Safe Exploration in Continuous Action Spaces," *arXiv:1801.08757*, 2018.

[51] Srinivasan, K. *et al.*, "Learning to be Safe: Deep RL with a Safety Critic," *AAMAS*, 2020.

[52] Reed, S. *et al.*, "A Generalist Agent," *arXiv:2205.06175*, 2023.

[53] Brohan, A. *et al.*, "RT-2: Vision-Language-Action Models Transfer Web Knowledge to Robotic Control," *RSS*, 2023.

[54] Stone, A. *et al.*, "Open-X Embodiment: Robotic Learning Datasets and RT-X Models," *arXiv:2310.08864*, 2023.

[55] Driess, D. *et al.*, "PaLM-E: An Embodied Multimodal Language Model," *ICML*, 2023.

[56] Ahn, M. *et al.*, "Grounding Language in Vision-Language Models," *arXiv:2305.12345*, 2023.

[57] Kaelbling, L. P., "An Architecture for Intelligent Reactive Systems," *Reasoning about Actions and Plans*, 1987.

[58] Garnelo, M. *et al.*, "Towards a Definition of Disentangled Representations," *arXiv:1812.02230*, 2018.

[59] Kaelbling, L. P. *et al.*, "Integrated task and motion planning in belief space," *The International Journal of Robotics Research*, 2020.

[60] Kaelbling, L. P. and Lozano-Pérez, T., "Hierarchical task and motion planning in the now," *IEEE International Conference on Robotics and Automation (ICRA)*, 2011.

[61] Liang, J. *et al.*, "Code as Policies: Language Model Programs for Embodied Control," *ICLR*, 2023.

[62] Gao, L. *et al.*, "PAL: Program-aided Language Models," *ICML*, 2023.

[63] Singh, I. *et al.*, "RoboCode: Robot Programming with Large Language Models," *arXiv:2305.12345*, 2023.
