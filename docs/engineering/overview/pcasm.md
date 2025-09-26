# PCASM for real‑time, goal‑grounded perception and manipulation

PCASM—Partition, Compare, Attend, Summarize, Map—is a control layer that runs on top of your RGB‑D perception and language grounding. Each tick, you look at a belief‑state scene graph, decide what to sense more precisely, what to grasp or move, and how to push the world toward what the instruction asked you to achieve. It is not just a tree traversal; it is a disciplined way to propose, understand, prioritize, schedule, and effect state changes under hard real‑time budgets.

## The world state you actually have

At time \( t \), the robot’s belief is a triple \( X_t = (G_t, B_t, H_{0:t}) \), where:

- G_t is a typed scene graph: objects, their attributes and 6D poses, and relations like on_top_of, in, near, supports.
- B_t holds uncertainties and confidences from detectors, trackers, and pose estimators.
- H_{0:t} is history: tracks, successes and failures, operator corrections, and short logs that matter for scheduling and risk.

A natural‑language instruction \( L \) compiles into a goal specification \( \Phi \): predicates and constraints the world must satisfy, plus a small rule table that expresses affordances and preferences (for example, cylinders should be lifted with top suction; packets should be pinched at the side seam). We will return to how language becomes such rules.

## What the five functionals do (and don’t do)

PCASM separates five responsibilities cleanly:

- Partition proposes candidates from the current node and context. In practice, candidates are objects, affordance sites, or subgoals extracted from G_t. Partition does not score or select; it only exposes options.
- Summarize computes the sufficient statistics you need to decide. Use both item‑level summaries (class posteriors, 6D pose, geometry, reachability, semantic matches to the instruction) and set‑level summaries (how crowded the work area is, redundancy among options, risk indicators, partial coverage of the goal). Set‑level summaries are crucial for real‑time behavior because they let you gate redundant computations.
- Compare assigns scores or energies to candidates given the goal and uncertainty. A typical shape is \( s = \text{relevance} - \text{risk} + \text{progress} \), with an exploration bonus when uncertainty is high. This is where you encode distance to goal predicates, grasp success priors by object shape, and penalties for occlusions or collisions.
- Attend turns scores into a schedule under budgets. This is the real‑time gate: select the top few ROIs to refine with open‑vocabulary detectors, choose which grasps to attempt now, and decide whether to halt for this tick. Hard and soft policies live here: top‑k, thresholds, softmax weights, or stochastic selection when you want exploration.
- Map is the only place where state is written. It emits outputs (perception calls, motor commands, logs) and produces the next contexts for each selected child. Map also fuses new evidence, updates \( G_t \) and \( B_t \), records policy outcomes in \( H_{0:t} \), and advances the residual goal \( \Delta\Phi \). A clean mental rule: everything reads the context; only Map writes it.

## A minimal end‑to‑end pass in words

Suppose the instruction is “pick the red cylinder on the tray and place it into the left bin.” Partition proposes the currently visible objects and their feasible affordance sites (top cap for suction, side faces for pinch). Summarize computes item features: class posteriors from the base detector, 3D pose and top surface normal stability from depth, collision‑free approach angles, and the semantic compatibility of each object with “red cylinder.” Summarize also computes set features: the tray is crowded; only two candidates are red and cylindrical; the left bin is free.

Compare scores candidates as relevance − risk + progress: the red cylinder with a stable horizontal top cap and clear approach wins; the similar but orange cylinder loses relevance; the bag of packets loses affordance compatibility. Attend, given a 25‑ms budget, selects one object to refine with an open‑vocabulary model and one grasp site to validate with a quick physics check. Map dispatches the OWL or Grounding‑DINOv3 call on the selected ROI, updates the class posterior, commits the top‑slice suction plan, and produces the next context for the control loop to execute the approach and lift.

## Why this layout matters

Keeping selection separate from scoring and keeping all state updates inside Map pays off immediately. You can swap a greedy Attend for a top‑k or stochastic policy without touching Compare. You can add a set‑level Summarize that measures redundancy across candidates and get immediate throughput improvements. You can enforce tight latency by letting Attend be the single place where FLOPs, time slices, and halting decisions are honored.

## From the original framing to a corrected one

Your original text was directionally right, but two fusions blurred the design:

- Partition bundled generation, scoring, and selection. That hides the real‑time scheduler and makes budgets hard to reason about. We unbundle: Partition only proposes, Compare scores, Attend selects and schedules.
- Context updates sat in a separate Context function and scattered helpers. That makes behavior unpredictable when you mix policies. We move all context writes into Map; everything else sees context as read‑only.

Once you enforce these rules, the Required vs Optional discussion becomes crisp: all five exist in every run, but any can be identity. For instance, Attend can be identity when you process everything; Compare can be identity if scores are not needed; Summarize can be identity if Compare can read raw nodes. This keeps the algebra intact and the code easy to swap.

## Set‑theoretic PCASM (the algebra that makes it composable)

Let \( N \) be nodes, \( C \) contexts, \( F \) features, \( K \) scores, \( W \) schedules, \( O \) outputs. The five maps are:

\[
\begin{aligned}
P &:\; N \times C \to \mathcal{P}(N) \\
U_{\text{item}} &:\; N \times C \to F \\
U_{\text{set}} &:\; \mathcal{P}(N) \times C \to F_{\text{set}} \\
R &:\; (F \times F_{\text{set}} \times C) \to K \\
A &:\; K \times C \to W \\
M &:\; (N, C, S \subseteq N, F, F_{\text{set}}, K, W) \to (O, \\varphi)
\end{aligned}
\]

Here \( S \) is the subset produced by Attend. The function \( \varphi: S \to C \) supplies a per‑child next context. The runtime graph has vertices \( (n, c) \) and edges

\[
(n, c) \to (n', \varphi(n')), \quad n' \in S.
\]

If you key visited by a canonicalization of \( (n, c) \) (for example, a stable hash of object id plus coarse pose bin and policy mode), this graph is a DAG during one traversal.

Identity forms make optionality precise:

- P(n, c) = {n} when you do not branch,
- U = id when raw nodes are already features,
- R = const when you just need an order from elsewhere,
- A = process‑all when no scheduling is needed,
- M = (∅, c) when there are no outputs and the state does not change.

### What is existing state, relevance, and history in this algebra?

Existing state is \( X_t = (G_t, B_t, H_{0:t}) \). Context \( c \) is the slice of state the PCASM loop reads heavily each tick: budgets, planner flags, detector switches, seeds, and the current residual goal \( \Delta\Phi \). Relevance is a score inside Compare that ties the current goal to scene items:

\[
\mathrm{rel}(o \mid \Phi) = \sum_k w_k \, \mathbf{1}[o \; \text{participates in} \; \phi_k] \cdot \mathrm{compat}_k(o) - \lambda\,\mathrm{uncert}(o).
\]

Compatibility comes from language–vision grounding and uncertainty comes from \( B_t \). History enters as priors and dampers: Summarize can include empirical grasp success per shape; Compare can penalize affordances that recently failed; Attend can shrink budgets for detectors that underperform on this scene.

## Comparing a scene graph to a desired one

Language \( L \) produces a goal graph \( G^\star \) or a predicate set \( \Phi \). Progress requires aligning \( G_t \) to \( G^\star \) and measuring what is unsatisfied.

A simple scheme aligns nodes by cost

\[
c_{ij} = \lambda_c\,d_{\mathrm{class}} + \lambda_p\,d_{\mathrm{pose}} + \lambda_s\,d_{\mathrm{shape}} + \lambda_a\,d_{\mathrm{attr}},
\]

solved by an assignment algorithm. When relations matter, a Gromov–Wasserstein‑style alignment compares relational structures as well. The unmet predicates form \( \Delta\Phi \); Compare rewards actions that reduce \( \Delta\Phi \), and Map marks a predicate satisfied when an action completes.

## Language as policy: affordance routing from words

Instructions do not just specify what to do; they often imply how to grasp or place. A tiny, human‑readable rule table is enough:

```text
rule grasp:
  when class in {cylinder} and target=lift then action=grasp_top_slice
  when class in {packet, pouch} and target=lift then action=pinch_side
  default action=parallel_jaw_center
```

At runtime, language produces \( \Phi \) and this rule table. Attend applies the router under budget; Map executes the chosen action and records its outcome.

## Worked examples

### Cylinder vs packet

Pixels and depth show a red cylinder, a pouch, and a box on a tray. Partition proposes the three objects, plus candidate affordance sites (top cap for the cylinder, seams for the pouch, faces for the box). Summarize includes per‑item features: class probabilities; top cap planarity from depth; suctions’ clearance; seam continuity for the pouch; reachable approach vectors. Compare favors the cylinder’s top cap for a lift and penalizes the pouch for suction. Attend selects the cylinder and one pouch seam ROI for refinement. Map triggers a quick open‑vocabulary confirmation on the ROI, locks in the top‑slice suction for the cylinder, and updates the context to execute the approach while keeping the pouch seam queued for later.

### Place into bin

After a successful lift, Partition proposes candidate placements in the left bin. Summarize computes bin free volume, surface normals, and stability scores. Compare favors flat, empty subregions that yield satisfied predicates for in_bin(left). Attend selects one placement; Map generates the motion segment, updates G_t and ΔΦ, and logs success into history.

## Modes that match your runtime

PCASM supports three practical modes without changing the algebra:

- Lazy processes one selected candidate per step; you get excellent responsiveness with minimal buffering.
- Batched processes children in windowed chunks to stabilize ranking and amortize compute.
- Smart enables set‑level Summarize and uncertainty‑aware Compare; Attend then schedules both sensing and acting under a concrete latency budget.
