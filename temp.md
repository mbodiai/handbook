# How Our Scene Grammar Integrates with Dominant Approaches

In this chapter, we will:

- Survey ten dominant approaches in embodied AI, grouped into planning-centric and policy-centric categories, explaining each with formal insights and examples.
- Discuss how our explicit scene grammar approach can interoperate with these approaches (rather than treat them as competitors).

Throughout, we will reference relevant research to place our approach in context and to back key claims. Let's begin by examining the major approaches in embodied AI that informed our unified design.



**In our framework,**
we effectively have a built-in DSL: the language of our scene graph operations and skills.

Thus, this approach translates to finding a sequence (or program structure) of predicate-level operations that achieve $\varphi$. We can harness LLMs to propose such sequences in our ontology, then verify them (more on verification later). Program synthesis and classical planning are closely related – one can think of classical AI planning as a form of program synthesis where the "program" is a simple linear sequence of actions without complex control flow.

   1. Task-and-Motion Planning (TAMP)


**Within our framework,**
TAMP is naturally accommodated: our scene graph provides the symbolic layer (objects, relations), and we can call a motion planner to validate actions.

Essentially, when our planner considers an action like PickUp(A), we invoke a motion-planning module to see if a collision-free grasp path exists for object A. If not, that action is treated as not applicable in that state. In this way, our planning loop interweaves discrete search with continuous checks, effectively performing TAMP. A recent survey highlights that modern TAMP algorithms intermix logical and geometric reasoning in exactly this fashion[^1]. By having an explicit symbolic scene state, we can plug in motion planners as needed to check feasibility without leaving our framework. Task-and-motion planning isn't a separate paradigm for us; it is an added layer of constraint on our symbolic plans that we toggle on when geometry matters. We will revisit how we implement these geometric checks when we discuss our planning module.
**In our system,**
we integrate retrieval by keeping a log of all executed plans. Over time, this becomes a rich memory. Our planner uses a learned similarity metric over scene graphs to fetch relevant past cases (this similarity accounts for object types, spatial relations, and goal predicates). We then initialize a policy bias from those cases.

In practice, when enough analogous examples exist, the planner's job reduces to stitching together known solutions – it's planning by adaptation. If the current scenario is novel, the retrieval might not find close matches, and our planner will default to more exploratory search.

Thus, we gracefully interpolate between model-based search and memory-based reuse, depending on task familiarity. This retrieval-augmented strategy lies at the heart of our ability to scale to more complex tasks: the more the robot experiences, the less it has to brute-force compute anew. It aligns with trends in machine learning where experience replay and case memory improve decision-making efficiency[^10][^11].

   4. Behavior Trees (BTs) and Finite State Machines with Learned Leaves

A Behavior Tree is a hierarchical, tree-structured state machine commonly used in robotics and game AI for decision logic[^2]. It organizes actions and conditions in a tree where internal nodes control flow (e.g., sequence, fallback) and leaf nodes execute actions or check conditions. Finite state machines (FSMs) are a simpler formalism for sequencing behaviors. The key idea in modern robotics is to use BTs or FSMs as a skeleton of a policy, often with learned controllers at the leaves. That is, each leaf might invoke a learned skill (like a neural network policy for grasping), but the overall task logic (ordering, retries, conditional branching) is handled by the BT/FSM. Behavior Trees became popular for their modularity and reactivity – they can handle repeating a failed action or switching strategy if a condition is not met, which plain sequential plans cannot.

**Within our framework,**
we can generate a behavior tree from any high-level plan to execute it robustly.

For example, after planning a sequence [Pick(A), Place(A, B)], we could embed that into a BT that continuously checks if holding(A) predicate is true (after Pick) and retries Pick until true, then proceeds to Place, etc. The hierarchical structure of BTs is also useful for reusing subtrees (sub-policies) for repeated sub-tasks. In our implementation, we often treat the plan trace as producing a behavior tree for the executor: each step's preconditions become guard conditions, and if a step fails (precondition not achieved or action fails), the tree's fallback could invoke a re-plan or alternative strategy.

This approach is not unique to us; BTs have been widely adopted because they are interpretable by humans and can be designed modularly[^2]. They are not a fundamentally different planning paradigm, but a way to represent and run plans with built-in reactivity.

**Within our framework,**
we don't use ILP for every planning decision, but we do identify specific combinatorial subproblems where an optimizer can help.

For example, if our high-level plan requires distributing tasks among multiple agents, we might formulate that as an ILP to get an optimal allocation[^15]. Or if we have to choose which object to move first among many, we could set up a small ILP to minimize total extra moves (like a knapSack formulation). The key advantage is that general solvers can often handle complex constraints (like resource constraints, mutual exclusions, deadlines) more efficiently than naive search, because they employ sophisticated algorithms (branch-and-bound, cutting planes, etc.).

In practice, we integrate such solvers by:
-   Detecting when a planning subproblem fits a known pattern (e.g., a linear assignment or scheduling).
-   Compiling the relevant part of the scene graph and goal into an ILP model.
-   Solving it with a MILP/CP-SAT solver.
-   Translating the solver's solution back into predicates or plan steps.

For instance, we might have a predicate-level goal like "deliver packages P1, P2, P3 to destinations D1, D2, D3" and two robots. The assignment of packages to robots and the route each takes can be ILP-optimized (like a multi-Traveling Salesman Problem). The solver might output: RobotA handles P1->D1 and P3->D3 (with route order optimized), RobotB handles P2->D2. We then integrate this assignment into the plan (embedding each route as a sub-plan for each robot). By doing so, we ensure global optimality for that aspect, which a greedy planner might miss. One must be careful with solver size – ILPs can blow up in complexity. But modern solvers (CP-SAT in particular) are quite scalable for many practical cases, and they return optimal or near-optimal solutions with proofs of optimality in many cases.

We leverage them selectively to supercharge the planner when appropriate. This again shows that our scene grammar framework is flexible: it allows dropping down to specialized algorithms for parts of the problem without breaking the overall representation. Constraints defined in our ontology (like "at most one object in bin" or "minimize total moves") can be transformed into solver-friendly forms.

### 6. Vision-and-Language Action (VLA) Planner–Executor

A class of systems that use a pretrained Vision-Language model or Large Language Model to propose a high-level plan from an open-ended instruction, and then a low-level controller to execute it, ensuring feasibility. In other words, an LLM comes up with steps (leveraging its world knowledge and reasoning), but each suggested step is grounded by checking it against the robot's abilities or environment. A prominent example is Google's PaLM-SayCan system[^3], where an LLM (PaLM) generates possible next actions in natural language and a set of learned value functions estimate the feasibility of each action in the current state. The system selects the action with the highest value (feasible and useful) and executes it, then loops.

**In our framework,**
we implement a similar idea but with an even tighter integration: we parse language instructions into our predicate/scene graph format and possibly use an LLM in a constrained manner to help generate subgoals or plans, then we verify them with the scene graph (much like VeriGraph by Ekpo et al., which used a scene graph to validate LLM plans[^13]).

For instance, given an instruction, we might prompt an LLM: "Here is the current scene (list of predicates) and the goal. Propose a sequence of actions using this list of possible actions." The LLM's output is then checked: for each action, do the preconditions hold in our scene graph? If not, we either reject that action or insert corrective steps.

This is similar to the VLA idea but done at the symbolic level. One concrete example is SayCan in our lab: we have an LLM that suggests an action and a learned Q-function for each action that estimates probability of success. We only allow the action if its success probability is above some threshold[^3]. In a test scenario, the LLM suggested "pick up glass" but the success model gave it a low score (glass was out of reach), so the system instead tried "move closer to glass" (which had a high score), then later "pick up glass" became feasible.

This illustrates the LLM-augmented planning loop with feasibility gating.

