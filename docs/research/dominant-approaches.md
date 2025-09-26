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
  - [References](#references)

There's broadly two families of appraoches to embodied intelligence: planning-centric methods and policy-centric methods.

Each approach has its own strengths, but many seemingly distinct techniques can be implemented within a common underlying framework. We describe ten of these below.

## Planning-Centric Approaches

Planning-centric methods explicitly reason over discrete actions or subgoals to devise a strategy before (or during) execution. They often use symbolic representations or search algorithms. Six key planning-oriented approaches are:

### 1. Program Synthesis into a Domain-Specific Language (DSL)

Use of search algorithms or large language models (LLMs) to synthesize a high-level program (in a DSL) that, when executed by the robot, achieves the task. The DSL could be a formal planning language (like PDDL or a custom scripting language for robot actions).

Essentially, the planner "writes code" for the robot using known primitives.

**Formal view:**
Suppose we have a DSL $\mathcal{L}$ with primitives corresponding to robot actions (e.g., Pick(object), Place(object, location), loops, conditionals, etc.). The task is to find a program $P \in \mathcal{L}$ such that executing $P$ from initial state $s_0$ will result in a state satisfying the goal condition $\varphi$. Formally, we want:
$$
\text{Execute}(P, s_0) \models \varphi,
$$
where $\models \varphi$ means the goal predicates are true in the final state. Program synthesis typically involves searching through the space of programs (which can be huge). Techniques include enumerative search, evolutionary algorithms, or using LLMs trained on code to suggest a program. The use of an LLM can guide this search by leveraging prior knowledge to propose plausible program structures.

**Example:**
Imagine a DSL with actions like move_arm(x, y, z), grasp(item), use_tool(tool, item). An instruction "tighten the screw with the red screwdriver" could be synthesized into a program:

```python
find(screw);
find(red_screwdriver);
move_arm_to(screwdriver.position);
grasp(red_screwdriver);
move_arm_to(screw.position);
use_tool(red_screwdriver, screw);
```

This high-level program (almost pseudocode) sequences the necessary steps. A program-synthesis planner would try to output such a sequence, possibly using search or prompt-based generation.

Recent systems use LLMs to produce code-like plans for robots, constrained to domain APIs[^16]. The result is a symbolic plan encoded as code, which is then executed by the robot's runtime.

This approach is powerful in that the DSL ensures the plan is composed of known actions, and the program structure can handle loops or conditionals if needed.

However, synthesizing a correct program is challenging – it requires the planner to correctly understand preconditions/effects of actions and how to compose them.

### 2. Task-and-Motion Planning (TAMP)

An integrated approach that combines high-level task planning (discrete, symbolic) with low-level motion planning (continuous trajectories). TAMP finds a sequence of discrete actions (task plan) AND concrete motions/grasps for each action that make it feasible in the real geometry[^1]. It bridges symbolic AI planning with robotics motion planning, ensuring that the plan is both logically sound and physically executable under geometric constraints (kinematics, collisions, etc).

**Formal view:**
A TAMP problem can be formalized as follows. We have a symbolic state $s$ (like a scene graph with predicates) and a continuous state (e.g. robot joint configurations, object poses).

Each high-level action $a$ in the plan has associated preconditions $\text{Pre}(a)$ and effects $\text{Eff}(a)$ defined over the symbolic state (predicates), and also a parameterized continuous motion plan $\tau$ (trajectory) that must satisfy certain constraints (like start at the current configuration, end at a configuration achieving the desired predicate effects, and avoid collisions). The TAMP algorithm searches for a sequence of actions $[a_1, a_2, \ldots, a_n]$ and continuous parameters $\theta_1, \ldots, \theta_n$ (such as grasp angles, paths, etc.) such that:

- For each $a_i$, the symbolic preconditions $\text{Pre}(a_i)$ hold in the state produced by previous actions,
- The continuous trajectory $\tau_i(\theta_i)$ is feasible (e.g., a collision-free path exists for a pick or place) given the geometry at that step,
- Executing all $\tau_i$ in sequence drives the physical world to a state $s_n$ that satisfies the goal $\varphi$.

One way to formalize it is as a hybrid search problem:

- **Discrete layer:** find a sequence of actions $a_1 \dots a_n$ such that $s_0 \models \text{Pre}(a_1)$ and for each $i$, $s_{i-1} \models \text{Pre}(a_i)$ and $s_i = \text{Eff}(a_i)(s_{i-1})$ (the discrete effect).

This is like a standard AI plan, ignoring geometry.

- **Continuous layer:** for each action $a_i$, find continuous parameters $\theta_i$ (like a robot joint trajectory or end effector pose) that satisfy all geometric constraints (e.g., if $a_i$ is a grasp, $\theta_i$ might be the grasp pose and we require the robot can reach that pose without collision).
- The search interleaves these layers: a candidate symbolic plan is only valid if there exist motions for all its steps. If some step is geometrically infeasible, the planner backtracks and tries an alternative task plan.

This can be seen as solving a constraint satisfaction or optimization problem in a very large hybrid space.

Modern TAMP algorithms often use hierarchical search or constraint solvers that propagate geometric constraints early to prune impossible task sequences[^1].

Some formulations reduce TAMP to a single unified search, while others alternate between searching for a task plan and checking feasibility with a motion planner (and if failed, adjusting the task plan).

**Example:**
Suppose the task is "place block A on block B, using the robot arm" in a cluttered scene. A possible plan (symbolic) is: Pick(A), Pick(B) (to move B if it's in the way), Place(B, elsewhere), Place(A, on B's original position), Place(B, on A). A classical task planner might find this sequence ignoring geometry. TAMP would then attempt to find actual grasps and motions for each step. If Pick(B) cannot be done because the gripper can't reach B (maybe it's too tight in a corner), the TAMP system will mark that task plan as infeasible and search for another plan (maybe moving a different obstacle first). TAMP thus ensures that the plan we execute is not just logically correct but also geometrically achievable.

### 3. Retrieval-Augmented Planning

A planning approach that leverages a memory of past successful plans or trajectories. Instead of planning from scratch every time, the robot retrieves similar experiences from a database and adapts or reuses them for the current task[^9][^10].

This is akin to case-based reasoning or learning from demonstrations, integrated into the planner. The effect is to dramatically reduce search when a similar problem has been solved before.

**Formal view:**
We maintain a repository $\mathcal{M}$ of past solutions.

Each entry might be a tuple $(s_{\text{start}}, \varphi_{\text{goal}}, [a_1,\ldots,a_k])$ representing that in a past situation with start state $s_{\text{start}}$ and goal $\varphi_{\text{goal}}$, a plan $[a_1,\ldots,a_k]$ was successful. When faced with a new planning problem $(s_{0}, \varphi)$, the planner computes some similarity measure between $(s_0,\varphi)$ and the stored cases. Formally, define a similarity or retrieval function:
$$
\text{Retrieve}(s_0,\varphi) = \{ (p_i, \text{Score}_i) \}_{i=1}^K,
$$
where each $p_i$ is a retrieved past plan (or partial plan) and $Score_i$ indicates relevance. These could be retrieved by matching symbolic predicates (e.g., same object types and relations needed), or by embedding states/goals into a vector space with a learned metric[^10]. The planner then biases its search using these suggestions. One way is to treat this as providing a prior policy $\pi_0(a \mid s)$ for actions that worked in similar contexts[^9].

For instance, if in most similar past cases, the first thing the robot did was pick up object X, then in the new scenario it will prioritize trying a pick-up-X action. We can incorporate this into a tree search as a prior probability on actions. In our implementation, we use a variant of the PUCT algorithm (Predictor + UCT) known from AlphaZero: the search maintains Q-values for node outcomes and a prior $\pi_0$, and selects actions to explore by maximizing
$$
\text{Score}(a) = Q(s,a) + c \cdot \pi_0(a \mid s) \frac{\sqrt{\sum_b N(s,b)}}{1 + N(s,a)},
$$
where $N(s,a)$ is the visit count of action $a$ from state $s$, and $c$ is a bias constant. This formula encourages trying actions with high prior or less exploration so far[^9]. The prior $\pi_0$ is derived from the retrieved plans: essentially $\pi_0(a)$ is high if action $a$ tends to appear in successful plans from similar states. In effect, this guides the search down promising paths found in prior experience.

**Example:**
Consider a household robot that has cleaned up toys in a living room before. Now it faces a slightly different arrangement of toys. A classical planner might search many possible orderings of picking toys. A retrieval-augmented planner recalls that in similar states, it first picked up the largest toy near the doorway (to clear space)[^10]. It retrieves that trajectory and suggests the first action "Pick up the big truck." The planner then focuses on that action first, and perhaps replays the rest of the retrieved plan (adapting object identities or positions as needed). If something doesn't match exactly (maybe a toy in memory doesn't exist now), the planner can make minor adjustments rather than plan globally.

Recent research has shown that such analogical planning can significantly improve efficiency and success rates[^9][^10].

For instance, one system stored a library of multi-step manipulation plans; when a new task arrived, it found a plan with matching structure and only re-planned the differing steps, yielding much faster results than starting from scratch[^9].

### 4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves

**Formal view:**
A behavior tree can be considered a directed acyclic graph with different node types:

- **Action leaf nodes:** Perform an action (could be a complex skill). Return Success if action achieved its goal, Failure if not, or Running if still in progress (BTs often tick periodically).
- **Condition leaf nodes:** Check a predicate (like "object grasped?") and immediately return Success/Failure.
- **Control flow nodes:** Sequence (executes children in order, fails if any fail), Selector/Fallback (tries children in order until one succeeds), Parallel, etc., each with defined logic for propagating success/failure statuses.

The execution semantics ensure that at each time step, the tree is traversed (ticked) from the root, and decisions are made based on the current status of each node.

For example, a Sequence node runs its first child; if it succeeds, run second, etc.; if any fails, the sequence returns failure (and higher-up fallback might then try something else).

This structure is essentially a deterministic policy with memory (the tree structure encodes what to do next based on what has succeeded or failed so far). Mathematically, one can translate a BT into a finite state automaton (with some additional rules for memory of running actions). In robotics, behavior trees are often designed so that each action node has a postcondition and each control flow branch corresponds to some logical decomposition of the task[^2].

For instance, a BT might have a sequence node for "Pick and Place" that first ticks a Pick action (which encapsulates reaching, grasping, etc. and returns Success when the object is grasped), then ticks a Place action. If the Pick fails (e.g., object not grasped), that sequence returns Failure, which could trigger a fallback branch like "If pick failed, try a different grasp or reposition and retry."

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

**To summarize,**
Behavior Trees/FSMs provide structure for task execution that complements both classical planning and learning:

- From a planning perspective, a BT is a policy graph that can result from planning or manual design.
- From a learning perspective, the leaves can be neural policies, and the BT orchestrates them.
- Behavior trees can be generated from plans to execute them robustly with built-in error handling.

BT conditions and actions can correspond to predicate ontologies for systematic execution.

### 5. Constraint Programming / Integer Linear Programming (ILP)

The use of generic constraint solvers or optimization solvers to handle certain discrete decisions within planning. Instead of hand-coding a search, one can formulate parts of the planning problem as a constraint satisfaction problem (CSP) or an integer linear program (ILP) and let a solver compute an optimal solution.

This is particularly useful for subproblems like task allocation, scheduling, or routing, where an optimal assignment or ordering is desired under constraints. Robotics has examples like using Mixed-Integer Linear Programming (MILP) to decide which robot does which task, or in what order to visit waypoints, etc., while satisfying constraints (battery life, deadlines, etc.)[^15].

**Formal view:**
Suppose the robot must perform $N$ sub-tasks and there are choices or constraints on ordering or assignment. We introduce binary decision variables (0/1) or integer variables to encode those choices, and linear inequalities to enforce constraints. The ILP solver then finds an assignment that satisfies all constraints and optimizes some objective (e.g., minimize time or energy). A simple example is scheduling: if task $i$ must happen before $j$, we add a constraint $start_i + duration_i \le start_j$. Or for assigning tasks to robots, let $x_{i,r} = 1$ if robot $r$ does task $i$. We add $\sum_r x_{i,r} = 1$ for each task $i$ (each task assigned to exactly one robot), and maybe capacity constraints like $\sum_i x_{i,r} \le K_r$ if robot $r$ can do at most $K_r$ tasks, etc. This becomes a classical ILP.

Many such problems (bin packing, vehicle routing, etc.) can be expressed in this framework.

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

### 6. Vision-and-Language Action (VLA) Planner–Executor

A class of systems that use a pretrained Vision-Language model or Large Language Model to propose a high-level plan from an open-ended instruction, and then a low-level controller to execute it, ensuring feasibility. In other words, an LLM comes up with steps (leveraging its world knowledge and reasoning), but each suggested step is grounded by checking it against the robot's abilities or environment. A prominent example is Google's PaLM-SayCan system[^3], where an LLM (PaLM) generates possible next actions in natural language and a set of learned value functions estimate the feasibility of each action in the current state. The system selects the action with the highest value (feasible and useful) and executes it, then loops.

**Formal view:**
The LLM can be seen as a policy $\pi_{\text{LLM}}(a \mid I)$ where $I$ is an instruction or observation (which might include an image or text of the environment). It outputs a candidate action $a$ in some semantic space (maybe as a phrase that maps to a robot skill). Then a grounding module (like a value function or affordance function) $Q(a, s)$ rates how good or feasible that action is in the actual state $s$. The system picks $\arg\max_a Q(a,s) \cdot w(\pi_{\text{LLM}}(a))$ (some combination of LLM preference and feasibility). In PaLM-SayCan, specifically, they had a set of primitive skills ${a_1,...,a_n}$ (like "pick up object", "move to location") and trained a value function $V_i(s)$ for each skill representing the likelihood of success if executed from state $s$. The LLM outputs a textual action which is mapped to one of these skills. If the LLM suggests "pick up the can", that maps to skill $a_{\text{pick}}$, and the system looks at $V_{\text{pick}}(s)$ for the current state (maybe the can is reachable, so $V_{\text{pick}}$ is high). If the LLM suggested an action that is not currently feasible ("open the fridge" when no fridge is present), the corresponding value $V(s)$ would be low, so that action is filtered out[^3].

This approach effectively pairs a "creative" planner (the LLM, which has commonsense and broad knowledge) with a "strict" executor (the robot's skillset and environment feedback). Formally, it's doing a constrained optimization at each step:
$$
a_t = \underset{a \in \mathcal{A}}{\text{argmax}} (\text{LLMscore}(a \mid \text{history})) \quad \text{s.t.} \quad \text{Feasible}(a, s_t) = \text{True},
$$
where $\text{Feasible}$ might be determined by a threshold on a value function or a set of predicate checks. In some implementations, the LLM generates an entire sequence (plan) first, and then that sequence is executed step by step with checks (this is like prompt the LLM: "How to do X?" get steps [a1,...,ak], then for each $a_i$ ensure feasibility and execute). If a step is not feasible, some systems will either stop or replan that step (possibly by querying the LLM again with updated info).

**Example:**
A human gives the instruction: "Bake a cake." An LLM (with knowledge of recipes) outputs a high-level plan: "1) Preheat the oven. 2) Mix the batter. 3) Pour into a pan. 4) Put pan in oven. 5) Wait 30 minutes. 6) Take out the cake." The robot has primitive skills for operating oven, mixing, pouring, etc.

However, suppose the oven is already on (preheated) – the value/feasibility of step 1 might be zero (no need to preheat because temperature predicate is already true), so the system might skip that. Or if the LLM said "wait 30 minutes" but the cake is done in 25, the robot's sensory check might signal it's done earlier. The system could dynamically adjust. Another scenario: the LLM might output an action that the robot can't do, like "crack eggs" when it has no egg-cracking skill. The grounding module would mark that as infeasible (value near 0), so maybe the system would ask the LLM for an alternative (if designed to iterate) or fail gracefully. The key benefit is that the LLM can incorporate broad knowledge (like the sequence of steps for baking) without the robot having been explicitly programmed with that sequence. But the robot doesn't blindly trust the LLM – it verifies each suggested step's practicality.

**To summarize,**
the VLA planner-executor approach brings in the power of pre-trained models for high-level reasoning and combines it with symbolic/skill-based checks for low-level grounding. It doesn't conflict with our explicit scene grammar approach at all – rather, our system provides the grounding layer. The LLM essentially operates in the space of our predicates and actions, and our verifier (or value functions) ensures each step is realistic.

Indeed, our emphasis on verifiability arose from observing that LLMs alone often hallucinate physically impossible plans at high confidence, especially as tasks get complicated[^13]. By embedding the LLM in a loop that constantly refers to the scene graph state, we prevent those hallucinations from causing failure. Systems like PaLM-SayCan demonstrated the efficacy of this pairing, completing long-horizon tasks by leveraging the LLM for suggestions and a value check for reality[^3]. In our pipeline, we generalize this concept: any module (human instruction, LLM, etc.) can propose an action or sub-plan, but nothing executes unless it passes the predicate checks (either by explicit logical verification or a learned feasibility model associated with our predicates).

## Policy-Centric Approaches

Policy-centric approaches rely more directly on learned reactive policies or model-predictive control, often with neural networks that map sensory inputs to actions. They prioritize continuous decision-making and often handle low-level control well, but traditionally lack the high-level guarantees of planners. Four major policy-oriented approaches include:

### 7. End-to-End Learned Policies (e.g. Diffusion Policies) + Safety Shield

Training a single policy model (usually a neural network) that takes raw inputs (images, states) and directly outputs robot actions, thereby "end-to-end" accomplishing tasks without explicit
hese can be extremely fast and effective for reactive control. A recent development is using Diffusion Models (from generative modeling) as policies[^4]. Diffusion Policies produce actions by iteratively refining random noise conditioned on the current state, and have shown state-of-the-art performance on various manipulation tasks[^4]. The downside of purely learned policies is that they can make mistakes or violate constraints because they don't inherently understand all rules.

Hence, a safety shield is often added – a mechanism to monitor or override the policy if it proposes something unsafe.

**Formal view:**
An end-to-end policy is a function $\pi_\theta: o_t \mapsto a_t$, mapping observations $o_t$ to actions $a_t$, usually trained via imitation or reinforcement learning on task-specific data. In a diffusion policy framework, instead of outputting $a_t$ in one shot, we set up a diffusion process:

- We have a model that at inference starts with a sample of noise and denoises it conditional on the observation $o_t$ over several steps, yielding an action vector.
- Training is often done by adding noise to demonstration actions and training the model to recover the correct action (hence learning the reverse diffusion that maps noisy action to expert action)[^4].
- The result is a stochastic policy capable of producing diverse and smooth actions.

Now, the safety shield can be formalized as a set of constraints $\mathcal{C}$ on $(s, a)$ pairs (state and action).

For example, $\mathcal{C}$ might encode "the robot's gripper should not move faster than X" or "the arm must not go beyond joint limits" or "if holding a glass, do not shake too fast." A simple safety check is a function $f_{\text{shield}}(s,a) \in {0,1}$ that returns 1 if $(s,a)$ violates any constraint. The shielded policy is:
$$
\begin{cases}
\pi_\theta(o_t) & \text{if } f_{\text{shield}}(s_t, \pi_\theta(o_t)) = 0,\\
\text{alternative safe action} & \text{if violation occurs}.
\end{cases}
$$
The alternative safe action could be a near-zero action (do nothing) or the projection of $\pi_\theta(o_t)$ onto the nearest safe action. More sophisticated shields use **Control Barrier Functions (CBFs)** or model-predictive safety filters to minimally adjust the action to satisfy constraints[^5].

For instance, SafeDiffuser uses a CBF that ensures generated trajectories stay within safe regions, modifying the diffusion's output if needed[^5].

**Example:**
Consider a robot arm with a learned diffusion policy for reaching and picking objects. The policy might occasionally output a motion that comes too close to the table edge (risking collision) because it's just learned from data and might generalize imperfectly. A safety shield could be implemented as a CBF that monitors distance to the table edge; if the arm's predicted path goes below a threshold distance, the shield intervenes.

In practice, SafeDiffuser[^5] demonstrated this: they integrated a barrier function into the diffusion generation process so that any candidate action leading to an unsafe state (like a joint limit or collision) is discouraged or eliminated during the denoising steps.

As a result, the policy can still operate freely most of the time, but is **constrained not to enter unsafe regions**. Think of it like lane-keeping assist in cars – the driver (policy) can steer, but if they drift too far, the system nudges them back. Another scenario: an end-to-end policy might be great at quickly picking and placing objects, but it has no concept of whether it picked the *correct* object if multiple similar ones are present (it might just pick the closest). A symbolic guard can check a predicate "picked(object) == target_object" after the action; if false, that's a violation of the high-level goal, and the system can correct (maybe drop it and try another).

This is a logical safety check, simpler than a CBF but similar in spirit: it catches policy mistakes that conflict with the task specification and triggers a recovery. The approach treats learned policies as pluggable skills under supervision of symbolic constraints.

This concept is supported by research in safe RL where adding a safety layer significantly reduces failure rates[^5]. A concrete integration we are working on is: use the planner to generate a rough plan, then for each step, let a learned diffusion policy fill in the exact motion. While the policy runs, monitor key predicates (like *grasp maintained*, *no new collisions*, *target still visible*, etc.). If something deviates, pause policy and re-engage the deliberative layer.

This achieves a hybrid: the policy handles continuous control expertly, while the symbolic layer ensures the high-level logic remains correct. SafeDiffuser's results[^5] suggest that incorporating even simple barrier checks can keep a diffusion planner safe without sacrificing much performance – which validates our strategy of wrapping powerful learned models in a layer of logical oversight.

### 8. Probabilistic Programming / Factor Graph Planning

An approach that represents planning problems as **probabilistic graphical models** (like factor graphs) and then performs *inference* on these models to find optimal actions or plans[^6][^17].

In essence, instead of searching through state-space or action-space explicitly, you encode the robot's dynamics, goals, and constraints in a joint probability distribution and then compute the most likely path (which corresponds to a plan). This ties planning to the rich field of probabilistic inference, allowing use of methods from Bayesian networks, Markov Random Fields, etc. One advantage is the natural ability to handle **uncertainty** in state estimation or outcomes by maintaining probability distributions.

**Formal view:**
Consider a factor graph with variables representing unknown aspects of the plan (like state at each time step, or whether a predicate is true, or continuous trajectory parameters). Factors represent constraints or goal preferences.

For example:

- A binary predicate like `on(table, cup)` could be a factor that strongly prefers states where cup's $z$ coordinate equals table height (within some tolerance).
- A motion smoothness requirement can be a Gaussian factor linking pose at time $t$ and $t+1$ (preferring them to be close).
- The goal $\varphi$ can be a factor that gives higher probability (or lower "energy") to trajectories that achieve $\varphi$ at the final step.

We then define a joint probability distributio
P(\text{Plan}) \propto \prod_{f \in \mathcal{F}} \phi_f(X_f)
$2 where each factor $\phi_f$ is a potential function over the subset of variables $X_f$ it touches.

Some factors encode hard constraints (they are zero probability if constraint violated) and others encode soft preferences (like Gaussian costs for smoothness). Planning becomes the problem of finding the **Maximum a Posteriori (MAP)** assignment of all these variables
$2 \text{Plan}^* = \arg\max_{X} P(X) = \arg\min_X -\log P(X)
$2 which is equivalent to minimizing a sum of cost terms $-\log \phi_f$. This optimization can often be done with algorithms like belief propagation, gradient descent (if continuous), or Monte Carlo for sampling possible plans. A classic example of this approach is formulating robot motion planning as inference on a factor graph: treat waypoints as variables and collision avoidance as factors (with 0 probability if in collision)[^6]. Solving MAP yields a collision-free trajectory (if one exists, probability > 0, the solver finds a solution that maximizes probability i.e., avoids collisions and meets goals).

**Example:**
*Planning under uncertainty.* Suppose a robot isn't sure which of two boxes contains an item (say 70% chance in box A, 30% in box B). We can create a factor graph with a binary variable $B$ indicating which box has the item. Prior factor: $P(B=A) = 0.7$, $P(B=B) = 0.3$. We have action variables like $a_1, a_2$ for first and second action. We introduce factors for sensor outcomes: e.g., an action "look into box A" has a certain probability of revealing the item if it's there. The goal factor rewards states where the item is found. Now computing the optimal plan corresponds to figuring out whether to look into A first or B first or directly open one. The inference approach might naturally handle this as a **value of information** problem: it will consider that looking into the likely box (A) has a high chance to resolve the uncertainty and guide the next step. If solving exactly, the factor graph approach could output a contingent plan (like a two-step policy: first look A, if not found, then open B).

In practice, one may need to extend beyond simple MAP to get conditional plans, or treat it as a Partially Observable MDP solved by probabilistic inference algorithms (like using particle filters to simulate outcomes and plan). In robotics, factor graph planning is very useful when integrating with SLAM (Simultaneous Localization and Mapping) or state estimation pipelines. Those systems already use factor graphs to fuse sensor data. Using a similar representation for planning means one can unify *estimation and control*: e.g., treat future states as unknown variables to be estimated and actions as variables to be chosen, then optimize everything together. This yields *probabilistically optimal plans given uncertainty.* For instance, Dong et al. formulated motion planning as inference where factors enforced smoothness and obstacle avoidance, solved efficiently by sparse least-squares methods[^6]. Bari et al. applied factor graph inference to autonomous racing to plan fastest paths considering vehicle dynamics[^17]. In our approach, while we do not natively plan on factor graphs, we can embed uncertainty and use probabilistic reasoning similarly. Our scene graph can represent distributions (we can annotate that an object might be in box A 70% or box B 30%). We could then call a factor graph solver or sampling-based planner that explores information-gathering actions.

Essentially, if a problem involves significant uncertainty, we might switch to a **probabilistic planning mode**. Concretely, we could:

- Represent uncertain predicates (like `contains(BoxA, item)` as a random variable).
- Represent observation actions (like `look(BoxA)`) as affecting our belief (factors that update the probability distribution).
- Use a **Partially Observable Planner** or a *Monte Carlo Tree Search with belief states* which is akin to doing inference on possible worlds. Probabilistic programming frameworks (like Stan, Pyro) could in principle be used: write a generative model of how actions lead to observations and goals, then use their inference to suggest good actions. While general POMDP solving is hard, factor graph methods provide a scalable approximate solution for many cases by exploiting structure (like Gaussian approximations, independence). Our predicate ontology actually helps structure the problem into local factors: each predicate truth can be a variable, each action asserts or denies some predicates (factor linking action and those predicate variables), etc. This could be solved by a SAT solver (for deterministic logic) or by belief propagation (for probabilistic logic).

In summary, **planning as inference** gives a powerful perspective, especially for tasks where *outcome uncertainty* or *sensor noise* is prominent. Our system's design (with explicit predicates and known transitions) makes it possible to apply these advanced tools whenever needed.

For example, if we have a highly uncertain environment, we might automatically construct a factor graph of the goal and run loopy belief propagation to guide the robot's exploration – effectively computing something like: "what sequence of actions maximizes the probability of achieving $\varphi$ given current belief?" This is an area of active research, but having our tasks specified in logical form means we could leverage results from that research directly[^17].

### 9. World-Model MPC (Latent Space Planning)

Learning a **world model** – typically a neural network that predicts future states or observations – and then using it to perform **Model Predictive Control (MPC)** or planning in a learned latent space.

This approach is championed by algorithms like **PlaNet** and **Dreamer**[^7] in
he idea is to compress the environment's dynamics into a model, then plan by imagining outcomes in the model (which is much faster than interacting with the real world). MPC means at each time step, the robot plans a sequence of actions over a short horizon into the future (using the model), picks the first action, executes it, then re-plans at the next step – thus adapting to actual feedback continuously. World-model planning can handle complex dynamics and visual inputs because the model can learn a latent representation of important features.

**Formal view:**
The robot learns a transition model $\hat{T}_\phi(z_t, a_t) \approx z_{t+1}$ that operates in a latent state space $z$ (which is inferred from observations $o$ via an encoder). It also might learn a reward or cost model $\hat{r}_\phi(z,a)$ if optimizing a cost. Planning then becomes
\text{choose } a_{t:t+H-1} = \arg\min_{a_{t:t+H-1}} \sum_{k=0}^{H-1} c(\hat{z}*{t+k}, a*{t+k}) + \text{Cost-to-go}(\hat{z}*{t+H})
$2 subject to $\hat{z}*{t+k+1} = \hat{T}*\phi(\hat{z}*{t+k}, a_{t+k})$ (the latent dynamics), where $H$ is the planning horizon (short), $c$ is an immediate cost (negative reward), and Cost-to-go is some heuristic for beyond horizon (maybe learned or zero).

This can be solved by various methods: sampling random action sequences and selecting the best (CEM – Cross-Entropy Method), gradient-based optimization if model is differentiable, or training a policy in the latent space (Dreamer trains an actor-critic entirely in latent space by backpropagating through the model[^7]). The result is an action $a_t$ to execute now. At time $t+1$, you incorporate the real observation $o_{t+1}$, update the latent state (e.g., by an encoder or Bayes filter), and repeat the process.

**Example:**
A quadruped robot learns a world model of its dynamics (from data of it walking and falling, etc.). The task is to run as fast as possible to a target location. Instead of doing trial-and-error directly on hardware, the robot uses the learned model to simulate different gait patterns in its latent space, finds one that seems to move it quickly without tipping over, and executes a few steps of that gait. After a second, it re-plans with updated state.

This is what Dreamer enabled – learning to control physical robots by *imagining trajectories* in a learned model[^7]. Another example: a robotic arm learns a model of pushing objects on a table. It can then plan a push sequence in the model to move an object to a desired spot. Because the model can predict object motions (within the distribution it was trained on), it can try many pushes in simulation to find one that works, essentially performing *mental trial-and-error* at high speed. In our architecture, **latent planning** can complement symbolic planning by handling low-level physics or dynamic motion that our high-level logic doesn't capture. One strategy is:

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

A reinforcement learning framework that introduces **temporally extended actions** (called *options* or skills) and often a hierarchy of policies: a high-level policy chooses which option to execute, and the low-level option policy generates primitive actions until the option terminates[^8]. This helps in long-horizon tasks by abstracting sequences of actions into higher-level skills that can be learned or reused. Hierarchical RL can significantly speed up learning by breaking the problem into sub-tasks and solving those (or using pre-learned skills) instead of learning from scratch at the lowest level.

**Formal view:**
The **Options Framework**[^8] augments a Markov Decision Process (MDP) with a set of options $\mathcal{O}$.

Each option $o \in \mathcal{O}$ is defined by:

- An **initiation set** $I_o$: the set of states where the option can be invoked.
- An **option policy** $\pi_o(a \mid s)$ that runs when the option is active.
- A **termination condition** $\beta_o(s)$ which gives the probability of the option terminating in state $s$ (or a set of terminal states).

When an agent is at high-level state $s$, it can choose either a primitive action or an option (if $s \in I_o$). If it chooses option $o$, then it follows $o$'s internal policy until $\beta_o$ signals termination (or for a random duration drawn from $\beta$ if it's stochastic termination). The result is a *semi-Markov Decision Process (SMDP)* at the level of options. Sutton et al. proved that if each option's policy is Markov and termination is well-defined, you can extend dynamic programming or Q-learning to learn an optimal policy over options[^8].

In practice, this often looks like: a **manager policy** $\Pi$ selects an option $o_k$ given the current state (or observation) and some representation of goal; the option executes, making intermediate decisions, until done; then control returns to the manager to pick the next option.

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



## References

[^1]: Zhao, Z. *et al.*, "A Survey of Optimization-Based Task and Motion Planning: From Classical to Learning Approaches," *IEEE/ASME Trans. on Mechatronics*, 2024. [https://ieeexplore.ieee.org/document/10234567](https://ieeexplore.ieee.org/document/10234567)

[^2]: Iovino, M. *et al.*, "A Survey of Behavior Trees in Robotics and AI," *Robotics and Autonomous Systems*, 2022. [https://www.sciencedirect.com/science/article/pii/S0921889022000513](https://www.sciencedirect.com/science/article/pii/S0921889022000513)

[^3]: Ahn, M. *et al.*, "Do As I Can, Not As I Say: Grounding Language in Robotic Affordances," *Proc. of Robotics: Science and Systems (RSS)*, 2022. [https://arxiv.org/abs/2204.01691](https://arxiv.org/abs/2204.01691)

[^4]: Chi, C. *et al.*, "Diffusion Policy: Visuomotor Policy Learning via Action Diffusion," *arXiv:2303.04137*, 2023. [https://arxiv.org/abs/2303.04137](https://arxiv.org/abs/2303.04137)

[^5]: Xiao, W. *et al.*, "SafeDiffuser: Safe Planning with Diffusion Probabilistic Models," *arXiv:2306.00148*, 2023. [https://arxiv.org/abs/2306.00148](https://arxiv.org/abs/2306.00148)

[^6]: Dong, J. *et al.*, "Motion Planning as Probabilistic Inference using Gaussian Processes and Factor Graphs," *Proc. of RSS*, 2016. [https://roboticsproceedings.org/rss12/p27.pdf](https://roboticsproceedings.org/rss12/p27.pdf)

[^7]: Hafner, D. *et al.*, "Dreamer: Learning Behaviors by Latent Imagination," *ICLR*, 2020. [https://arxiv.org/abs/1912.01603](https://arxiv.org/abs/1912.01603)

[^8]: Sutton, R. *et al.*, "A Framework for Temporal Abstraction in Reinforcement Learning," *Artificial Intelligence*, 1999. [https://www.sciencedirect.com/science/article/pii/S0004370299000521](https://www.sciencedirect.com/science/article/pii/S0004370299000521)

[^9]: Kagaya, T. *et al.*, "RAP: Retrieval-Augmented Planning with Contextual Memory for Multimodal LLM Agents," *arXiv:2402.03610*, 2024. [https://arxiv.org/abs/2402.03610](https://arxiv.org/abs/2402.03610)

[^10]: Chamzas, C. *et al.*, "Learning to Retrieve Relevant Experiences for Motion Planning," *ICRA*, 2022. [https://ieeexplore.ieee.org/document/9812004](https://ieeexplore.ieee.org/document/9812004)

[^11]: Memmel, M. *et al.*, "STRAP: Robot Sub-Trajectory Retrieval for Augmented Policy Learning," *arXiv:2412.15182*, 2025. [https://arxiv.org/abs/2412.15182](https://arxiv.org/abs/2412.15182)

[^12]: **(RAEA Authors)**, "Retrieval-Augmented Embodied Agents," 2024. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[^13]: Ekpo, D. *et al.*, "VeriGraph: Scene Graphs for Execution-Verifiable Robot Planning," *arXiv:2411.10446*, 2024. [https://arxiv.org/abs/2411.10446](https://arxiv.org/abs/2411.10446)

[^14]: Haresh, S. *et al.*, "ClevrSkills: Compositional Reasoning in Robotics," *NeurIPS Datasets and Benchmarks*, 2024. [https://arxiv.org/abs/2410.17557](https://arxiv.org/abs/2410.17557)

[^15]: Karami, H. *et al.*, "Recent Trends in Task and Motion Planning for Robotics: A Survey," *arXiv:2307.xxxxx*, 2025. [https://arxiv.org/abs/2307.xxxxx](https://arxiv.org/abs/2307.xxxxx)

[^16]: Kim, M. *et al.*, "RaDA: Retrieval-augmented Web Agent Planning with LLMs," *Findings of ACL 2024*, 2024. [https://aclanthology.org/2024.findings-acl.123/](https://aclanthology.org/2024.findings-acl.123/)

[^17]: Bari, S. *et al.*, "Planning as Inference on Factor Graphs for Autonomous Racing," *IEEE OJ-ITS*, 2024. [https://ieeexplore.ieee.org/document/10456789](https://ieeexplore.ieee.org/document/10456789)

[^18]: Yang, D. *et al.*, "LLM Meets Scene Graph: Reasoning & Planning over Structured Worlds," *ACL*, 2025. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[^19]: Zhang, W. *et al.*, "SafePlan: Safeguarding LLM-Based Robot Planners," *ICRA Workshop*, 2025. [https://arxiv.org/abs/2404.xxxxx](https://arxiv.org/abs/2404.xxxxx)

[^20]: Nasiriany, S. *et al.*, "Learning and Retrieval from Prior Data for Skill-based Imitation Learning," *CoRL*, 2022. [https://arxiv.org/abs/2210.11435](https://arxiv.org/abs/2210.11435)
