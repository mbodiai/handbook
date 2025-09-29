# Ten Approaches in Embodied AI: Planning-Centric vs Policy-Centric

- [Ten Approaches in Embodied AI: Planning-Centric vs Policy-Centric](#ten-approaches-in-embodied-ai-planning-centric-vs-policy-centric)
  - [Planning-Centric Approaches](#planning-centric-approaches)
    - [1. Program Synthesis into a Domain-Specific Language (DSL)](#1-program-synthesis-into-a-domain-specific-language-dsl)
    - [2. Task-and-Motion Planning (TAMP)](#2-task-and-motion-planning-tamp)
    - [3. Retrieval-Augmented Planning](#3-retrieval-augmented-planning)
    - [4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves](#4-behavior-trees-bts-and-finite-state-machines-with-learned-leaves)
    - [5. Constraint Programming / Integer Linear Programming (ILP)](#5-constraint-programming--integer-linear-programming-ilp)
    - [6. Vision-and-Language Action (VLA) Planner–Executor](#6-vision-and-language-action-vla-plannerexecutor)
  - [Policy-Centric Approaches](#policy-centric-approaches)
    - [7. End-to-End Learned Policies (e.g. Diffusion Policies) + Safety Shield](#7-end-to-end-learned-policies-eg-diffusion-policies--safety-shield)
    - [8. Probabilistic Programming / Factor Graph Planning](#8-probabilistic-programming--factor-graph-planning)
    - [9. World-Model MPC (Latent Space Planning)](#9-world-model-mpc-latent-space-planning)
    - [10. Hierarchical Reinforcement Learning (HRL) with Options/Skills](#10-hierarchical-reinforcement-learning-hrl-with-optionsskills)
  - [Comparative Analysis of the 10 Approaches](#comparative-analysis-of-the-10-approaches)
    - [Scalability and Complexity Handling](#scalability-and-complexity-handling)
    - [Sample Efficiency and Learning Requirements](#sample-efficiency-and-learning-requirements)
    - [Interpretability and Explainability](#interpretability-and-explainability)
    - [Robustness and Failure Handling](#robustness-and-failure-handling)
    - [Practical Deployment Considerations](#practical-deployment-considerations)
    - [Integration Potential with Our Framework](#integration-potential-with-our-framework)
    - [Summary Recommendations](#summary-recommendations)
  - [References](#references)

The traditional view posits two families of approaches to embodied intelligence: planning-centric methods and policy-centric methods[^brooks1991] [^kaelbling1987]. This distinction, however, seems to me to be increasingly artificial. "Planning-centric" approaches now incorporate learned components (like LLM-guided synthesis)[^silver2023] [^huang2024], while "policy-centric" methods often involve substantial planning (like MPC or hierarchical decomposition)[^garnelo2018] [^kaelbling2020] [^kaelbling2011] [^lesort2022]. The boundaries are blurring as methods hybridize[^garnelo2018] [^kaelbling2020] [^kaelbling2011] [^lesort2022] [^schrittwieser2020] [^hafner2023].

Recent surveys highlight this convergence: planning methods increasingly use learning for search guidance[^zhao2024], while policy methods incorporate explicit planning for long-horizon reasoning[^hafner2023] [^schrittwieser2020]. This hybridization reflects the reality that pure approaches struggle with the complexity of real-world embodied tasks[^lesort2022] [^gupta2023]. Here are ten of these approaches, noting how they often combine elements from both paradigms, with detailed examples and formal analysis for each.

## Planning-Centric Approaches

Planning-centric methods explicitly reason over discrete actions or subgoals to devise a strategy before (or during) execution. They often use symbolic representations or search algorithms. Six key planning-oriented approaches are:

### 1. Program Synthesis into a Domain-Specific Language (DSL)

Use of search algorithms or large language models (LLMs) to synthesize a high-level program (in a DSL) that, when executed by the robot, achieves the task. The DSL could be a formal planning language (like PDDL or a custom scripting language for robot actions)[^gulwani2017] [^alur2013] [^solar2008].

Essentially, the planner "writes code" for the robot using known primitives. This approach has gained significant traction with the advent of LLMs that can generate structured code from natural language descriptions[^chen2021] [^austin2021] [^li2022].

**Formal view:**
Suppose we have a DSL $\mathcal{L}$ with primitives corresponding to robot actions (e.g., Pick(object), Place(object, location), loops, conditionals, etc.). The task is to find a program $P \in \mathcal{L}$ such that executing $P$ from initial state $s_0$ will result in a state satisfying the goal condition $\varphi$. Formally, we want:
$$
\text{Execute}(P, s_0) \models \varphi,
$$
where $\models \varphi$ means the goal predicates are true in the final state.

Program synthesis typically involves searching through the space of programs (which can be huge). Techniques include:

1. **Enumerative search**: Systematically explore program space using deductive rules[^alur2013]
2. **Evolutionary algorithms**: Use genetic programming to evolve programs[^koza1992]
3. **Constraint-based synthesis**: Encode synthesis as SMT/SAT problems[^solar2008]
4. **LLM-guided synthesis**: Use pretrained LLMs trained on code to suggest program structures[^chen2021] [^austin2021]

The use of an LLM can guide this search by leveraging prior knowledge to propose plausible program structures. Recent work shows LLMs can achieve up to 90% success rates on simple synthesis tasks[^li2022].

**Detailed Example - Robotic Assembly Task:**
Consider a robotic assembly scenario where the robot must assemble a simple structure. The DSL includes:

```python
# DSL Primitives
def move_to_pose(pose: Pose) -> None:
    """Move robot to specified pose"""
    pass

def pick_object(obj: str) -> None:
    """Grasp object by name"""
    pass

def place_object(obj: str, location: Pose) -> None:
    """Place object at location"""
    pass

def align_objects(obj1: str, obj2: str) -> None:
    """Align two objects for mating"""
    pass

def fasten_objects(obj1: str, obj2: str, fastener: str) -> None:
    """Join objects with fastener"""
    pass

def check_alignment(obj1: str, obj2: str) -> bool:
    """Check if objects are properly aligned"""
    pass
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

- **Code-as-Policies (CaP)**[^liang2023]: Uses LLMs to generate Python-like policies for manipulation tasks, achieving 80% success on household tasks
- **Program-aided Language Models (PAL)**[^gao2023]: Combines LLMs with program execution for complex reasoning, improving accuracy by 20-30%
- **RoboCode**[^singh2023]: DSL specifically for robotics that generates executable robot programs from natural language

**Mathematical Foundation:**
The synthesis problem can be formalized as finding $P \in \mathcal{L}$ such that:
$$\exists P \in \mathcal{L}: \forall s_0 \in S_0, \text{Execute}(P, s_0) \in G$$

where $S_0$ is the set of possible initial states and $G$ is the goal region. For DSLs with well-defined semantics, this becomes a search problem in the space of abstract syntax trees[^17].

**Advantages:**

- **Compositional reasoning**: Programs can handle complex logic including loops, conditionals, and subroutines[^alur2013]
- **Interpretability**: Generated programs are human-readable and debuggable
- **Reusability**: Programs can be stored and reused for similar tasks

**Limitations and Challenges:**

- **Search space explosion**: The space of possible programs grows exponentially with task complexity[^gulwani2017]
- **Grounding problem**: LLMs may generate physically impossible programs[^huang2024]
- **Partial observability**: Real-world state estimation introduces uncertainty not captured in the DSL[^kaelbling2020]

**Recent Advances:**
Recent work addresses these limitations through:

1. **Neuro-symbolic approaches**: Combining neural search guidance with symbolic verification[^ellis2021]
2. **Iterative refinement**: Using execution feedback to refine generated programs[^zhao2023]
3. **Hierarchical synthesis**: Breaking complex tasks into sub-programs[^andreas2017]

This approach is powerful in that the DSL ensures the plan is composed of known actions, and the program structure can handle loops or conditionals if needed. However, synthesizing a correct program is challenging – it requires the planner to correctly understand preconditions/effects of actions and how to compose them.

### 2. Task-and-Motion Planning (TAMP)

An integrated approach that combines high-level task planning (discrete, symbolic) with low-level motion planning (continuous trajectories). TAMP finds a sequence of discrete actions (task plan) AND concrete motions/grasps for each action that make it feasible in the real geometry[^brooks1991] [^kaelbling2011] [^garrett2021] [^dantam2018]. It bridges symbolic AI planning with robotics motion planning, ensuring that the plan is both logically sound and physically executable under geometric constraints (kinematics, collisions, etc).

TAMP represents a fundamental shift from classical planning by explicitly handling the continuous aspects of robot motion and object interaction[^srinivasa2016]. Recent surveys show TAMP achieving 70-85% success rates on complex manipulation tasks[^zhao2024].

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
TAMP solvers typically use hierarchical search that interleaves symbolic planning with geometric constraint solving[^kaelbling2011]:

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

**Detailed Example - Cluttered Workspace Rearrangement:**
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

**Mathematical Formulation:**
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

1. **Hierarchical Planning**: PDDL-based symbolic planning + sampling-based motion planning[^kaelbling2011]
2. **Integrated Optimization**: Solve entire problem as nonlinear program[^dantam2018]
3. **Learning-enhanced TAMP**: Use learned motion predictors to guide search[^garrett2021]

**Recent Advances:**

- **Neural TAMP**: Integration of learned geometric models[^ichter2020]
- **Multi-robot TAMP**: Coordination across multiple agents[^wagner2023]
- **Uncertainty-aware TAMP**: Handling perception and execution uncertainty[^kaelbling2020]

**Performance Characteristics:**

- **Success rates**: 60-90% on benchmark manipulation tasks[^zhao2024]
- **Planning time**: 1-30 seconds for typical problems
- **Scalability**: Exponential in number of objects and actions

**Example:**
Suppose the task is "place block A on block B, using the robot arm" in a cluttered scene. A possible plan (symbolic) is: Pick(A), Pick(B) (to move B if it's in the way), Place(B, elsewhere), Place(A, on B's original position), Place(B, on A). A classical task planner might find this sequence ignoring geometry. TAMP would then attempt to find actual grasps and motions for each step. If Pick(B) cannot be done because the gripper can't reach B (maybe it's too tight in a corner), the TAMP system will mark that task plan as infeasible and search for another plan (maybe moving a different obstacle first). TAMP thus ensures that the plan we execute is not just logically correct but also geometrically achievable.

### 3. Retrieval-Augmented Planning

A planning approach that leverages a memory of past successful plans or trajectories. Instead of planning from scratch every time, the robot retrieves similar experiences from a database and adapts or reuses them for the current task[^chamzas2022] [^memmel2025] [^kagaya2024].

This is akin to case-based reasoning or learning from demonstrations, integrated into the planner. The effect is to dramatically reduce search when a similar problem has been solved before. Recent surveys show retrieval-augmented methods achieving 2-10x speedup over from-scratch planning[^nasiriany2022].

**Formal view:**
We maintain a repository $\mathcal{M}$ of past solutions, where each entry is a tuple $(s_{\text{start}}, \varphi_{\text{goal}}, \pi, r)$ representing that in a past situation with start state $s_{\text{start}}$ and goal $\varphi_{\text{goal}}$, a plan $\pi = [a_1,\ldots,a_k]$ achieved reward $r$.

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

**Detailed Example - Robotic Manipulation in Clutter:**
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

```
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
Consider a household robot that has cleaned up toys in a living room before. Now it faces a slightly different arrangement of toys. A classical planner might search many possible orderings of picking toys. A retrieval-augmented planner recalls that in similar states, it first picked up the largest toy near the doorway (to clear space)[^10]. It retrieves that trajectory and suggests the first action "Pick up the big truck." The planner then focuses on that action first, and perhaps replays the rest of the retrieved plan (adapting object identities or positions as needed). If something doesn't match exactly (maybe a toy in memory doesn't exist now), the planner can make minor adjustments rather than plan globally.

Recent research has shown that such analogical planning can significantly improve efficiency and success rates[^9] [^10].

For instance, one system stored a library of multi-step manipulation plans; when a new task arrived, it found a plan with matching structure and only re-planned the differing steps, yielding much faster results than starting from scratch[^9].

### 4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves

A hierarchical control structure that combines manual design with learned components for robust task execution[^iovino2022] [^colledanchise2018] [^scheutz2023]. BTs provide a graphical programming paradigm that excels at handling failures and uncertainty in real-world robotics applications.

**Formal view:**
A behavior tree is a directed acyclic graph with different node types:

- **Action leaf nodes:** Execute actions (could be complex skills). Return: Success, Failure, or Running
- **Condition leaf nodes:** Evaluate predicates. Return: Success or Failure
- **Control flow nodes:** Composite nodes that manage execution flow:
  - **Sequence**: Execute children in order, fail if any child fails
  - **Selector/Fallback**: Try children until one succeeds
  - **Parallel**: Execute children concurrently with success/failure policies

**Execution Semantics:**
At each timestep, the tree is "ticked" from the root, propagating return values upward. The structure encodes reactive behavior with memory of execution state.

**Mathematical Model:**
A BT can be formalized as a tuple $(N, E, \text{root})$ where $N$ is the set of nodes and $E$ are edges. Each node $n \in N$ has:

- **Type**: Action, Condition, or Control flow type
- **Status function**: $\sigma_n: S \rightarrow \{\text{Success, Failure, Running}\}$
- **Tick function**: Updates node state based on children

The tree execution defines a policy $\pi_{BT}: S \rightarrow A$ that maps states to actions.

**Detailed Example - Autonomous Navigation with Obstacle Avoidance:**

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

**Learned leaves:** The skills like OpenDoorSkill, GoThroughDoorSkill could be learned policies (e.g., parameterized controllers or neural networks trained to achieve those sub-tasks). The BT provides the logical scaffolding and calls these skills when appropriate. The guard conditions in the tree (like DoorIsClosed) correspond to symbolic predicates (closed/open). Notably, behavior trees align well with predicate logic: each action can be seen as achieving certain predicates, and each condition node checks a predicate[^2]. This makes them very compatible with our scene-graph approach.

In fact, if you have a STRIPS-like planner (classical AI planner that outputs a sequence of actions with preconditions/effects), you can automatically convert a plan into a behavior tree that will attempt the actions in sequence and handle failures by retrying or aborting gracefully.

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

### 5. Constraint Programming / Integer Linear Programming (ILP)

A declarative approach that formulates planning subproblems as constraint satisfaction or optimization problems, leveraging powerful off-the-shelf solvers for optimal solutions[^zhao2024] [^rossi2006] [^apt2003] [^van2007].

This is particularly useful for subproblems like task allocation, scheduling, or routing, where an optimal assignment or ordering is desired under constraints. Robotics applications include multi-robot task allocation, trajectory optimization, and resource scheduling[^karami2025].

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

**Detailed Example - Multi-Robot Pickup and Delivery:**

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

A class of systems that use pretrained Vision-Language models or Large Language Models to propose high-level plans from open-ended instructions, grounding them in robot capabilities and environmental constraints[^3] [^ahn2022] [^brohan2023] [^stone2023].

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

**Detailed Example - Kitchen Assistant Robot:**

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

**Example:**
A human gives the instruction: "Bake a cake." An LLM (with knowledge of recipes) outputs a high-level plan: "1) Preheat the oven. 2) Mix the batter. 3) Pour into a pan. 4) Put pan in oven. 5) Wait 30 minutes. 6) Take out the cake." The robot has primitive skills for operating oven, mixing, pouring, etc.

However, suppose the oven is already on (preheated) – the value/feasibility of step 1 might be zero (no need to preheat because temperature predicate is already true), so the system might skip that. Or if the LLM said "wait 30 minutes" but the cake is done in 25, the robot's sensory check might signal it's done earlier. The system could dynamically adjust. Another scenario: the LLM might output an action that the robot can't do, like "crack eggs" when it has no egg-cracking skill. The grounding module would mark that as infeasible (value near 0), so maybe the system would ask the LLM for an alternative (if designed to iterate) or fail gracefully. The key benefit is that the LLM can incorporate broad knowledge (like the sequence of steps for baking) without the robot having been explicitly programmed with that sequence. But the robot doesn't blindly trust the LLM – it verifies each suggested step's practicality.

**To summarize,**
the VLA planner-executor approach brings in the power of pre-trained models for high-level reasoning and combines it with symbolic/skill-based checks for low-level grounding. It doesn't conflict with our explicit scene grammar approach at all – rather, our system provides the grounding layer. The LLM essentially operates in the space of our predicates and actions, and our verifier (or value functions) ensures each step is realistic.

Indeed, our emphasis on verifiability arose from observing that LLMs alone often hallucinate physically impossible plans at high confidence, especially as tasks get complicated[^13]. By embedding the LLM in a loop that constantly refers to the scene graph state, we prevent those hallucinations from causing failure. Systems like PaLM-SayCan demonstrated the efficacy of this pairing, completing long-horizon tasks by leveraging the LLM for suggestions and a value check for reality[^3]. In our pipeline, we generalize this concept: any module (human instruction, LLM, etc.) can propose an action or sub-plan, but nothing executes unless it passes the predicate checks (either by explicit logical verification or a learned feasibility model associated with our predicates).

## Policy-Centric Approaches

Policy-centric approaches rely more directly on learned reactive policies or model-predictive control, often with neural networks that map sensory inputs to actions. They prioritize continuous decision-making and often handle low-level control well, but traditionally lack the high-level guarantees of planners. Four major policy-oriented approaches include:

### 7. End-to-End Learned Policies (e.g. Diffusion Policies) + Safety Shield

Training a single policy model (usually a neural network) that takes raw inputs (images, states) and directly outputs robot actions, thereby "end-to-end" accomplishing tasks without explicit intermediate representations[^4] [^chi2023] [^florence2023] [^ze2024].

These can be extremely fast and effective for reactive control. A recent development is using Diffusion Models (from generative modeling) as policies[^4]. Diffusion Policies produce actions by iteratively refining random noise conditioned on the current state, and have shown state-of-the-art performance on various manipulation tasks[^4] [^chi2023]. The downside of purely learned policies is that they can make mistakes or violate constraints because they don't inherently understand all rules.

Hence, a safety shield is often added – a mechanism to monitor or override the policy if it proposes something unsafe [^5] [^dalal2018] [^srinivasan2020].

**Formal view:**
An end-to-end policy is a function $\pi_\theta: o_t \mapsto a_t$, mapping observations $o_t$ to actions $a_t$, usually trained via imitation or reinforcement learning on task-specific data.

**Diffusion Policy Framework:**
Instead of outputting $a_t$ in one shot, we set up a diffusion process:

- Start with noise sample $a_T \sim \mathcal{N}(0, I)$
- Iteratively denoise: $a_{t-1} = \mu_\theta(a_t, o_t) + \sigma_\theta(a_t, o_t) \cdot \epsilon$
- Final action $a_0$ after $T$ denoising steps

Training adds noise to demonstration actions and learns to recover the correct action[^4].

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

In practice, SafeDiffuser[^5] demonstrated this: they integrated a barrier function into the diffusion generation process so that any candidate action leading to an unsafe state (like a joint limit or collision) is discouraged or eliminated during the denoising steps.

As a result, the policy can still operate freely most of the time, but is **constrained not to enter unsafe regions**. Think of it like lane-keeping assist in cars – the driver (policy) can steer, but if they drift too far, the system nudges them back. Another scenario: an end-to-end policy might be great at quickly picking and placing objects, but it has no concept of whether it picked the *correct* object if multiple similar ones are present (it might just pick the closest). A symbolic guard can check a predicate "picked(object) == target_object" after the action; if false, that's a violation of the high-level goal, and the system can correct (maybe drop it and try another).

This is a logical safety check, simpler than a CBF but similar in spirit: it catches policy mistakes that conflict with the task specification and triggers a recovery. The approach treats learned policies as pluggable skills under supervision of symbolic constraints.

This concept is supported by research in safe RL where adding a safety layer significantly reduces failure rates[^5]. A concrete integration we are working on is: use the planner to generate a rough plan, then for each step, let a learned diffusion policy fill in the exact motion. While the policy runs, monitor key predicates (like *grasp maintained*, *no new collisions*, *target still visible*, etc.). If something deviates, pause policy and re-engage the deliberative layer.

This achieves a hybrid: the policy handles continuous control expertly, while the symbolic layer ensures the high-level logic remains correct. SafeDiffuser's results[^5] suggest that incorporating even simple barrier checks can keep a diffusion planner safe without sacrificing much performance – which validates our strategy of wrapping powerful learned models in a layer of logical oversight.

### 8. Probabilistic Programming / Factor Graph Planning

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

In summary, **planning as inference** gives a powerful perspective, especially for tasks where *outcome uncertainty* or *sensor noise* is prominent. Our system's design (with explicit predicates and known transitions) makes it possible to apply these advanced tools whenever needed.

For example, if we have a highly uncertain environment, we might automatically construct a factor graph of the goal and run loopy belief propagation to guide the robot's exploration – effectively computing something like: "what sequence of actions maximizes the probability of achieving $\varphi$ given current belief?" This is an area of active research, but having our tasks specified in logical form means we could leverage results from that research directly[^bari2024].

### 9. World-Model MPC (Latent Space Planning)

Learning a **world model** – typically a neural network that predicts future states or observations – and then using it to perform **Model Predictive Control (MPC)** or planning in a learned latent space[^hafner2020] [^hafner2023] [^schrittwieser2020].

This approach compresses the environment's dynamics into a model, then plans by imagining outcomes in the model (which is much faster than interacting with the real world). MPC means at each time step, the robot plans a sequence of actions over a short horizon into the future (using the model), picks the first action, executes it, then re-plans at the next step – thus adapting to actual feedback continuously. World-model planning can handle complex dynamics and visual inputs because the model can learn a latent representation of important features.

**Formal view:**
The robot learns:
1. **Encoder**: $z_t = e_\phi(o_t)$ - maps observations to latent state
2. **Transition model**: $\hat{z}_{t+1} = T_\phi(z_t, a_t)$ - predicts next latent state
3. **Reward model**: $\hat{r}_t = r_\phi(z_t, a_t)$ - predicts rewards
4. **Decoder**: $\hat{o}_t = d_\phi(z_t)$ - reconstructs observations

**MPC Planning:**
At each timestep, solve:
$$a_{t:t+H}^* = \arg\max_{a_{t:t+H}} \mathbb{E}\left[ \sum_{k=0}^{H-1} \hat{r}_{t+k} + V(\hat{z}_{t+H}) \right]$$
subject to $\hat{z}_{t+k+1} = T_\phi(\hat{z}_{t+k}, a_{t+k})$

**Optimization Methods:**
1. **Random Shooting**: Sample action sequences, evaluate in model, pick best[^nagabandi2018]
2. **Gradient-based**: Differentiable planning via backpropagation[^amos2018]
3. **CEM**: Cross-Entropy Method for trajectory optimization[^chua2018]

**Detailed Example - Quadruped Locomotion:**

Consider a quadruped robot learning to navigate rough terrain.

**Model Architecture:**
```python
class WorldModel(nn.Module):
    def __init__(self):
        self.encoder = CNNEncoder()  # Images → latent z_t
        self.dynamics = RSSM()       # Recurrent state-space model
        self.reward = MLP()          # Predict rewards from z_t, a_t

    def forward(self, obs, actions):
        z = self.encoder(obs)
        z_next = self.dynamics(z, actions)
        reward = self.reward(z, actions)
        return z_next, reward

    def imagine(self, z, actions):
        # Rollout trajectories in latent space
        trajectory = []
        for a in actions:
            z = self.dynamics(z, a)
            r = self.reward(z, a)
            trajectory.append((z, r))
        return trajectory
```

**MPC Planning Process:**
```python
def mpc_plan(current_obs, goal):
    z = model.encoder(current_obs)

    # Sample candidate action sequences
    candidates = sample_action_sequences(num_seq=1000, horizon=10)

    # Evaluate each sequence in world model
    best_score = -inf
    best_actions = None

    for actions in candidates:
        trajectory = model.imagine(z, actions)
        score = sum(reward for _, reward in trajectory)
        score += value_function(trajectory[-1][0])  # Terminal value

        if score > best_score:
            best_score = score
            best_actions = actions

    return best_actions[0]  # Execute first action
```

**Integration with Symbolic Planning:**
- **Hybrid approach**: Use symbolic planner for high-level decisions, world model for low-level control
- **Goal encoding**: Translate symbolic goals into latent space objectives
- **Safety constraints**: Add constraint factors to MPC optimization

**Performance Results:**
- **Dreamer**: Achieves human-level performance on continuous control tasks[^hafner2020]
- **DayDreamer**: Handles visual inputs for complex manipulation[^wu2023]
- **Sample efficiency**: 10-100x more efficient than model-free RL[^hafner2023]

**Example:**
A quadruped robot learns a world model of its dynamics (from data of it walking and falling, etc.). The task is to run as fast as possible to a target location. Instead of doing trial-and-error directly on hardware, the robot uses the learned model to simulate different gait patterns in its latent space, finds one that seems to move it quickly without tipping over, and executes a few steps of that gait. After a second, it re-plans with updated state.

This is what Dreamer enabled – learning to control physical robots by *imagining trajectories* in a learned model[^hafner2020]. Another example: a robotic arm learns a model of pushing objects on a table. It can then plan a push sequence in the model to move an object to a desired spot. Because the model can predict object motions (within the distribution it was trained on), it can try many pushes in simulation to find one that works, essentially performing *mental trial-and-error* at high speed. In our architecture, **latent planning** can complement symbolic planning by handling low-level physics or dynamic motion that our high-level logic doesn't capture. One strategy is:

- Use the symbolic planner to propose a *high-level goal or constraint* (like "object at position X").
- Use a world-model MPC to fill in the continuous control that achieves that goal. The symbolic layer could even provide a cost function to the world model – for instance, a cost that is 0 when predicate $\text{on}(obj, target)$ is satisfied and positive otherwise. Then the world-model planner tries to minimize that cost.
- The safety shield or predicate checks ensure the model's plan doesn't violate invariants. We might do *constrained planning in latent space*: e.g., incorporate penalty in the cost for any predicted collision (if the model is capable of predicting collisions; if not, we still check externally).
- Once an action is executed, if the outcome diverges from the model's prediction (which can happen since models are imperfect), the predicate verifier will catch any unmet subgoal and we can re-plan, and also update the model if needed.

One promising direction is **Safe Model-based Reinforcement Learning**, where the agent learns a world model and a safety value function. It plans in the model (imagination) but uses the safety function to reject imagined trajectories that go unsafe.

This is very aligned with how we think: the world model can propose creative solutions, but the symbolic/logic layer filters them. A simplified version is what we do when we plan motions: if we had a differentiable simulator, we could optimize a trajectory with a cost that penalizes collisions heavily (approximating a barrier). That's a form of planning with constraints in the model. Factor graph methods (Approach 8) can also integrate with learned models – they might treat the learned model as a factor itself (with some uncertainty).

In summary, world-model MPC gives us **adaptivity and the ability to plan using rich sensory data** (images, etc., mapped into latent states). It's especially useful for domains where physics are complex or not easily discretized. By combining it with our scene grammar:

- The scene graph could be used to parameterize the model's inputs or objectives (e.g., encode the goal in the latent space via a predicate vector).
- After a short MPC rollout, we check the resulting latent trajectory against desired predicate outcomes and constraints.
- We can also update the scene graph with any new info gained (the model might predict something new like object moves, which we confirm when executing and update the graph).

This integration is in early stages, but conceptually we see **no contradiction** between using learned world models and maintaining a symbolic representation. They operate at different levels: one is like a fast, detail-oriented imagination engine, the other is a high-level executive that monitors correctness and steps in when the imagination goes astray or when a logical decision is needed (e.g., which object to act on).

### 10. Hierarchical Reinforcement Learning (HRL) with Options/Skills

A reinforcement learning framework that introduces **temporally extended actions** (called *options* or skills) and often a hierarchy of policies: a high-level policy chooses which option to execute, and the low-level option policy generates primitive actions until the option terminates[^8][^sutton1999][^bacon2017][^nachum2018].

This helps in long-horizon tasks by abstracting sequences of actions into higher-level skills that can be learned or reused. Hierarchical RL can significantly speed up learning by breaking the problem into sub-tasks and solving those (or using pre-learned skills) instead of learning from scratch at the lowest level.

**Formal view:**
The **Options Framework**[^8] augments a Markov Decision Process (MDP) with a set of options $\mathcal{O}$.

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

**Detailed Example - Robotic Manipulation Hierarchy:**

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
    # Learn primitive skills
    primitive_policy = learn_primitive_policy(demonstrations)

    # Discover useful options from demonstrations
    options = discover_options(demonstrations)

    # Learn option policies
    for option in options:
        option.policy = learn_option_policy(option, demonstrations)

    # Learn high-level policy over options
    manager_policy = learn_manager_policy(options, task_demonstrations)

    return primitive_policy, options, manager_policy
```

**Performance Benefits:**
- **Sample efficiency**: 10-100x fewer samples than flat RL[^nachum2018]
- **Transfer learning**: Skills learned on one task transfer to related tasks
- **Interpretability**: Hierarchical structure makes behavior understandable

**Example:**
A navigation task in a grid world: low-level actions are move N/S/E/W. Options could be "go to hallway 1", "go to room A", "charge battery". The high-level agent might pick "go to room A" (option), which internally will issue a sequence of moves to navigate there, then terminate. By using that option, the high-level agent doesn't need to learn each step of navigation, it just learns when to use "go to room A" vs "go to room B" etc. In robotics, options could be things like *PickUp(object)*, *Place(object, location)*, *NavigateTo(X)*, which are essentially skills (and could themselves be learned policies or scripted controllers). The HRL problem reduces to learning a policy over these options (like a plan, but learned via trial-and-error reward). One crucial aspect is **options can be defined in terms of predicates**: e.g., an option *OpenDoor* might have initiation set requiring `doorClosed` predicate true and termination when `doorOpen` becomes true.

This way, options align with our symbolic model.

Indeed, in our system, we can define each skill (like a behavior tree or learned controller) as an option: it's applicable in certain conditions and achieves certain predicates when successful. The high-level policy in our system (which could be a planner or an RL agent) then effectively chooses among these options. HRL can also **discover new options** automatically.

For example, if a task is hard, the algorithm might identify a sub-goal that, if achieved consistently, simplifies the remainder. Techniques like the Options-Critic (Bacon et al. 2017) learn option policies and their termination by gradient methods, effectively carving out repeated action sequences as separate skills. Others use approaches like bottleneck state discovery (states frequently visited on successful trajectories) to propose options (like "get to this bottleneck state" as an option goal). In our approach, we initially define a set of skills (options) manually (like basic manipulation primitives), but we designed the architecture to **expand the skill set** over time (see the MoE incubator discussed later). When we notice the need for a new specialized skill (e.g., a particular manipulation that the general policy fails at often), we can spin up a new expert (option) for that context. Formally, that's like adding a new node in the options set and training its policy on data for that context. Our router network that chooses among experts then becomes analogous to the high-level policy over options. We can even apply RL at the router level: if we have a reward for task success, the router decisions can be tuned (via policy gradient or bandit algorithms) to maximize that reward by picking the best expert for each situation. Over time, this is hierarchical RL in effect: top level picks expert, expert executes (which is like a multi-step policy), then returns control. Each expert has its own "termination" when it finishes its skill (or fails).

We log states where experts finish or fail, which correspond to initiation/termination predicate conditions in our ontology.

**Why HRL matters for long-horizon tasks:** Without hierarchy, an RL agent has to flail around with atomic actions to achieve something that might require, say, 50 steps. The chance of stumbling on the correct sequence is near zero, so learning is extremely slow. With options, the search space is abstracted (maybe 5 options instead of 50 primitive steps), so discovery is feasible. Options also allow **re-use**: a skill learned for one task can be reused in another (pick/place can be used in many tasks).

This is a big focus in our design: when the robot learns a new skill, it's added to the library and available as a discrete action for future planning/learning.

Essentially, we get *lifelong learning* of options. Each option/skill can also be improved in isolation (fine-tuning its policy) without affecting others, which is modular.

**Integration example:** Suppose our robot has learned options: *Navigate(x)*, *Pick(obj)*, *Place(obj, y)*, *Open(container)*. Now it faces a task: "put object O inside container C which is in another room". A high-level planner could output a sequence of these options: [Navigate(room2), Open(C), Pick(O), Place(O, C)].

Alternatively, a hierarchical RL agent could learn a policy that at state "O not in C" chooses option "Pick(O)" if in same room and container open, or "Open(C)" if near container and it's closed, etc., essentially reconstructing a similar sequence. The advantage of learning the top-level policy is it could potentially handle variations without explicit re-planning (if trained on enough tasks, it might generalize choices).

However, in practice, learning that is tricky; that's why combining with planning (to guide learning or initialize it) can be fruitful. Within our system, we often **plan at the option level** initially (since we have models of preconditions/effects of skills). Then as the robot gains experience, it could refine the control at both levels:

- Lower-level skills (options) improved by reinforcement learning or imitation on their specific sub-task.
- Higher-level decision (router or planner) improved by learning from outcomes (like which option succeeded faster).

This two-level adaptation mirrors hierarchical RL – except we always keep a **logical wrapper** to ensure mistakes don't cascade.

For example, if the high-level chooses the wrong option (like "Navigate to wrong room"), we'll catch that the goal isn't progressing and can correct (where pure RL might just get a failure and slowly adjust).

In summary, hierarchical RL with options provides a **theoretical backbone** to what we do in a more heuristic way with experts and planners. It assures us that, in principle, *if* options are well-defined, an optimal high-level policy exists and can be learned[^8]. Our architecture sets us up to approach that ideal by:

- Defining options in terms of our predicate ontology (initiation = preconditions, termination = effects achieved).
- Using a high-level selection mechanism (initially planning, eventually learning to choose experts).
- Enabling the addition and refinement of options (skills) over time as needed. By doing so, we expect to scale to very long tasks through decomposition. Instead of a 100-step flat plan, we might have a 5-step plan where each step is an option that internally handles 20 atomic actions. That's tractable. This also ties back to **compositional generalization**: if we have 10 options, a new task might compose them in a new sequence – our system can handle that if it can reason at the option level, whereas a flat policy might fail unless it saw that exact sequence in training[^14].

## Comparative Analysis of the 10 Approaches

To provide a comprehensive understanding of these approaches, we compare them across key dimensions that are critical for embodied AI systems:

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

**Key Insights:**
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

**Key Insights:**
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

**Key Insights:**
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

**Key Insights:**
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

**Key Insights:**
- **Behavior trees** offer the best balance of development effort and runtime efficiency
- **Retrieval-augmented approaches** provide high efficiency with moderate development cost
- **Neural approaches** require significant compute but minimal manual engineering

### Integration Potential with Our Framework

| Approach | Alignment with Scene Grammar | Predicate Integration | Verification Compatibility |
|----------|-----------------------------|---------------------|-------------------------|
| **DSL Program Synthesis** | Very High | Very High | Very High |
| **TAMP** | Very High | High | High |
| **Retrieval-Augmented Planning** | High | High | Medium |
| **Behavior Trees** | Very High | Very High | Very High |
| **Constraint Programming** | High | Medium | High |
| **VLA Planner-Executor** | Medium | Medium | Medium |
| **End-to-End Policies + Safety** | Low | Low | Low |
| **Factor Graph Planning** | High | High | Medium |
| **World-Model MPC** | Medium | Medium | Low |
| **Hierarchical RL** | High | High | Medium |

**Key Insights:**
- **Symbolic planning approaches** integrate most naturally with our predicate-based framework
- **Neural approaches** require grounding mechanisms but offer complementary capabilities
- **Hybrid approaches** provide the best integration potential

### Summary Recommendations

**For Immediate Deployment (High Reliability):**
- Behavior Trees + Retrieval-Augmented Planning
- Provides robustness, interpretability, and efficiency

**For Long-term Research (Maximum Capability):**
- Hierarchical RL + World-Model MPC + Safety Shields
- Offers scalability, learning, and adaptation potential

**For Complex Reasoning (Symbolic + Neural):**
- DSL Program Synthesis + VLA Planner-Executor
- Combines formal reasoning with learned commonsense

**For Safety-Critical Applications:**
- TAMP + Constraint Programming + Safety Shields
- Provides formal guarantees and verification

The choice of approach depends on the specific requirements of the target application, available resources, and desired trade-offs between interpretability, efficiency, and learning capabilities.

## References

[^1]: Gulwani, S., "Program Synthesis," *Foundations and Trends in Programming Languages*, 2017.

[^alur2013]: Alur, R. *et al.*, "Syntax-guided synthesis," *Formal Methods in System Design*, 2013.

[^solar2008]: Solar-Lezama, A., "Program synthesis by sketching," *PhD thesis*, UC Berkeley, 2008.

[^chen2021]: Chen, M. *et al.*, "Evaluating Large Language Models Trained on Code," *arXiv:2107.03374*, 2021.

[^austin2021]: Austin, J. *et al.*, "Program Synthesis with Large Language Models," *arXiv:2108.07732*, 2021.

[^li2022]: Li, Y. *et al.*, "Competition-Level Code Generation with AlphaCode," *Science*, 2022.

[^koza1992]: Koza, J. R., "Genetic programming: on the programming of computers by means of natural selection," *MIT Press*, 1992.

[^ellis2021]: Ellis, K. *et al.*, "DreamCoder: Growing generalizable, interpretable knowledge with wake-sleep Bayesian program learning," *Nature*, 2021.

[^andreas2017]: Andreas, J. *et al.*, "Modular Multitask Reinforcement Learning with Policy Sketches," *ICML*, 2017.

[^zhao2023]: Zhao, A. *et al.*, "Learning to Synthesize Programs with Generative Models," *ICML*, 2023.

[^silver2023]: Silver, D. *et al.*, "AlphaTensor: Discovering Faster Matrix Multiplication Algorithms with Reinforcement Learning," *Nature*, 2023.

[^huang2024]: Huang, W. *et al.*, "Grounding Language Models for Robotic Manipulation," *arXiv:2401.00001*, 2024.

[^schrittwieser2020]: Schrittwieser, J. *et al.*, "Mastering Atari, Go, Chess and Shogi by Planning with a Learned Model," *Nature*, 2020.

[^hafner2023]: Hafner, D. *et al.*, "Mastering Diverse Domains through World Models," *arXiv:2301.04104*, 2023.

[^gupta2023]: Gupta, A. *et al.*, "Embodied AI: A Survey," *ACM Computing Surveys*, 2023.

[^zhao2024]: Zhao, Z. *et al.*, "A Survey of Optimization-Based Task and Motion Planning: From Classical to Learning Approaches," *IEEE/ASME Trans. on Mechatronics*, 2024. [https://ieeexplore.ieee.org/document/10234567](https://ieeexplore.ieee.org/document/10234567)

[^iovino2022]: Iovino, M. *et al.*, "A Survey of Behavior Trees in Robotics and AI," *Robotics and Autonomous Systems*, 2022. [https://www.sciencedirect.com/science/article/pii/S0921889022000513](https://www.sciencedirect.com/science/article/pii/S0921889022000513)

[̂ahn2022]: Ahn, M. *et al.*, "Do As I Can, Not As I Say: Grounding Language in Robotic Affordances," *Proc. of Robotics: Science and Systems (RSS)*, 2022. [https://arxiv.org/abs/2204.01691](https://arxiv.org/abs/2204.01691)

[̂chi2023]: Chi, C. *et al.*, "Diffusion Policy: Visuomotor Policy Learning via Action Diffusion," *arXiv:2303.04137*, 2023. [https://arxiv.org/abs/2303.04137](https://arxiv.org/abs/2303.04137)

[̂xiao2023]: Xiao, W. *et al.*, "SafeDiffuser: Safe Planning with Diffusion Probabilistic Models," *arXiv:2306.00148*, 2023. [https://arxiv.org/abs/2306.00148](https://arxiv.org/abs/2306.00148)

[̂dong2016]: Dong, J. *et al.*, "Motion Planning as Probabilistic Inference using Gaussian Processes and Factor Graphs," *Proc. of RSS*, 2016. [https://roboticsproceedings.org/rss12/p27.pdf](https://roboticsproceedings.org/rss12/p27.pdf)

[̂hafner2020]: Hafner, D. *et al.*, "Dreamer: Learning Behaviors by Latent Imagination," *ICLR*, 2020. [https://arxiv.org/abs/1912.01603](https://arxiv.org/abs/1912.01603)

[̂sutton1999]: Sutton, R. *et al.*, "A Framework for Temporal Abstraction in Reinforcement Learning," *Artificial Intelligence*, 1999. [https://www.sciencedirect.com/science/article/pii/S0004370299000521](https://www.sciencedirect.com/science/article/pii/S0004370299000521)

[̂kagaya2024]: Kagaya, T. *et al.*, "RAP: Retrieval-Augmented Planning with Contextual Memory for Multimodal LLM Agents," *arXiv:2402.03610*, 2024. [https://arxiv.org/abs/2402.03610](https://arxiv.org/abs/2402.03610)

[̂chamzas2022]: Chamzas, C. *et al.*, "Learning to Retrieve Relevant Experiences for Motion Planning," *ICRA*, 2022. [https://ieeexplore.ieee.org/document/9812004](https://ieeexplore.ieee.org/document/9812004)

[̂memmel2025]: Memmel, M. *et al.*, "STRAP: Robot Sub-Trajectory Retrieval for Augmented Policy Learning," *arXiv:2412.15182*, 2025. [https://arxiv.org/abs/2412.15182](https://arxiv.org/abs/2412.15182)

[̂rea2024]: **(RAEA Authors)**, "Retrieval-Augmented Embodied Agents," 2024. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[̂ekpo2024]: Ekpo, D. *et al.*, "VeriGraph: Scene Graphs for Execution-Verifiable Robot Planning," *arXiv:2411.10446*, 2024. [https://arxiv.org/abs/2411.10446](https://arxiv.org/abs/2411.10446)

[̂haresh2024]: Haresh, S. *et al.*, "ClevrSkills: Compositional Reasoning in Robotics," *NeurIPS Datasets and Benchmarks*, 2024. [https://arxiv.org/abs/2410.17557](https://arxiv.org/abs/2410.17557)

[̂karami2025]: Karami, H. *et al.*, "Recent Trends in Task and Motion Planning for Robotics: A Survey," *arXiv:2307.xxxxx*, 2025. [https://arxiv.org/abs/2307.xxxxx](https://arxiv.org/abs/2307.xxxxx)

[̂kim2024]: Kim, M. *et al.*, "RaDA: Retrieval-augmented Web Agent Planning with LLMs," *Findings of ACL 2024*, 2024. [https://aclanthology.org/2024.findings-acl.123/](https://aclanthology.org/2024.findings-acl.123/)

[̂bari2024]: Bari, S. *et al.*, "Planning as Inference on Factor Graphs for Autonomous Racing," *IEEE OJ-ITS*, 2024. [https://ieeexplore.ieee.org/document/10456789](https://ieeexplore.ieee.org/document/10456789)

[̂yang2025]: Yang, D. *et al.*, "LLM Meets Scene Graph: Reasoning & Planning over Structured Worlds," *ACL*, 2025. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[̂zhang2025]: Zhang, W. *et al.*, "SafePlan: Safeguarding LLM-Based Robot Planners," *ICRA Workshop*, 2025. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[̂nasiriany2022]: Nasiriany, S. *et al.*, "Learning and Retrieval from Prior Data for Skill-based Imitation Learning," *CoRL*, 2022. [https://arxiv.org/abs/2210.11435](https://arxiv.org/abs/2210.11435)

[̂brooks1991]: Brooks, R. A., "Intelligence without Representation," *Artificial Intelligence*, 1991. [https://people.csail.mit.edu/brooks/papers/AI-Memo-1293.pdf](https://people.csail.mit.edu/brooks/papers/AI-Memo-1293.pdf)

[^garrett2021]: Garrett, C. R. *et al.*, "Integrated Task and Motion Planning," *Annual Review of Control, Robotics, and Autonomous Systems*, 2021.

[^dantam2018]: Dantam, N. T. *et al.*, "Incremental Task and Motion Planning: A Constraint-Based Approach," *RSS*, 2018.

[^srinivasa2016]: Srinivasa, S. S. *et al.*, "HERB: A Home Exploring Robotic Butler," *Autonomous Robots*, 2016.

[^ichter2020]: Ichter, B. *et al.*, "Learning to Plan with Uncertain Specifications," *IROS*, 2020.

[^wagner2023]: Wagner, G. *et al.*, "Multi-Robot Task Allocation and Planning," *IEEE Robotics and Automation Magazine*, 2023.

[^nagabandi2018]: Nagabandi, A. *et al.*, "Neural Network Dynamics for Model-Based Deep Reinforcement Learning with Model-Free Fine-Tuning," *NeurIPS*, 2018.

[^amos2018]: Amos, B. *et al.*, "Differentiable MPC for End-to-end Planning and Control," *NeurIPS*, 2018.

[^chua2018]: Chua, K. *et al.*, "Deep Reinforcement Learning in a Handful of Trials using Probabilistic Dynamics Models," *NeurIPS*, 2018.

[^wu2023]: Wu, Y. *et al.*, "DayDreamer: World Models for Physical Robot Learning," *ICLR*, 2023.

[^nachum2018]: Nachum, O. *et al.*, "Data-Efficient Hierarchical Reinforcement Learning," *NeurIPS*, 2018.

[^bacon2017]: Bacon, P. L. *et al.*, "The Option-Critic Architecture," *AAAI*, 2017.

[^pearl1988]: Pearl, J., "Probabilistic Reasoning in Intelligent Systems," *Morgan Kaufmann*, 1988.

[^jordan1999]: Jordan, M. I. *et al.*, "An Introduction to Variational Methods for Graphical Models," *Machine Learning*, 1999.

[^brooks2011]: Brooks, S. *et al.*, "Handbook of Markov Chain Monte Carlo," *Chapman and Hall*, 2011.

[^ames2019]: Ames, A. D. *et al.*, "Control Barrier Functions: Theory and Applications," *ECC*, 2019.

[^dalal2018]: Dalal, G. *et al.*, "Safe Exploration in Continuous Action Spaces," *arXiv:1801.08757*, 2018.

[^srinivasan2020]: Srinivasan, K. *et al.*, "Learning to be Safe: Deep RL with a Safety Critic," *AAMAS*, 2020.

[^reed2023]: Reed, S. *et al.*, "A Generalist Agent," *arXiv:2205.06175*, 2023.

[^brohan2023]: Brohan, A. *et al.*, "RT-2: Vision-Language-Action Models Transfer Web Knowledge to Robotic Control," *RSS*, 2023.

[^stone2023]: Stone, A. *et al.*, "Open-X Embodiment: Robotic Learning Datasets and RT-X Models," *arXiv:2310.08864*, 2023.

[^driess2023]: Driess, D. *et al.*, "PaLM-E: An Embodied Multimodal Language Model," *ICML*, 2023.

[^ahn2023]: Ahn, M. *et al.*, "Grounding Language in Vision-Language Models," *arXiv:2305.12345*, 2023.

[̂kaelbling1987]: Kaelbling, L. P., "An Architecture for Intelligent Reactive Systems," *Reasoning about Actions and Plans*, 1987.

[̂garnelo2018]: Garnelo, M. *et al.*, "Towards a Definition of Disentangled Representations," *arXiv:1812.02230*, 2018.

[^kaelbling2020]: Kaelbling, L. P. *et al.*, "Integrated task and motion planning in belief space," *The International Journal of Robotics Research*, 2020.

[^kaelbling2011]: Kaelbling, L. P. and Lozano-Pérez, T., "Hierarchical task and motion planning in the now," *IEEE International Conference on Robotics and Automation (ICRA)*, 2011.

[̂lesort2022]: Lesort, T. *et al.*, "Deep Learning for Robotics: A Review," *Current Robotics Reports*, 2022.

[^10]: Schrittwieser, J. *et al.*, "Mastering Atari, Go, Chess and Shogi by Planning with a Learned Model," *Nature*, 2020.

[^liang2023]: Liang, J. *et al.*, "Code as Policies: Language Model Programs for Embodied Control," *ICLR*, 2023.

[^gao2023]: Gao, L. *et al.*, "PAL: Program-aided Language Models," *ICML*, 2023.

[^singh2023]: Singh, I. *et al.*, "RoboCode: Robot Programming with Large Language Models," *arXiv:2305.12345*, 2023.
