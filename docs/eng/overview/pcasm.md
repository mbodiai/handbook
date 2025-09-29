# PCASM for real‑time, goal‑grounded perception and manipulation

PCASM—Partition, Compare, Attend, Summarize, Map—is a control layer that runs on top of your RGB‑D perception and language grounding. Each control tick examines a belief‑state scene graph, decides what to sense more precisely, what to grasp or move, and how to push the world toward the instructed objective. It is validation-as-computation tree traversal; it is a disciplined way to propose, understand, prioritize, schedule, and effect state changes under hard real‑time budgets.

## What the five functionals do

PCASM separates five core responsibilities that work together in a loop:

- **Partition** : Generates potential next states or options from the current node
- **Compare** : Ranks or scores options based on relevance, cost, or other metrics
- **Attend** : Selects which options to process based on their comparative scores
- **Summarize** : Extracts features or information needed for evaluation
- **Map** : Transforms selected nodes into final outputs or actions

### 1. Partition: Generate Options

Proposes candidates from the current node and context. In practice, candidates are objects, affordance sites, or subgoals extracted from the current scene graph. Partition does not score or select; it only exposes options.

### Summarize: Extract Features

Computes the sufficient statistics needed to decide. Uses both item‑level summaries (class posteriors, 6D pose, geometry, reachability, semantic matches to the instruction) and set‑level summaries (how crowded the work area is, redundancy among options, risk indicators, partial coverage of the goal). Set‑level summaries are crucial for real‑time behavior because they let you gate redundant computations.

### Compare: Score and Rank

Assigns scores or energies to candidates given the goal and uncertainty. A typical shape is:
$$
s = \mathrm{relevance} - \mathrm{risk} + \mathrm{progress}
$$
with an exploration bonus when uncertainty is high. This encodes distance to goal predicates, grasp success priors by object shape, and penalties for occlusions or collisions.

### Attend: Schedule Under Budget

Turns scores into a schedule under real‑time budgets. This is the gate: select the top few ROIs to refine with open‑vocabulary detectors, select grasp attempts and halting decisions for this tick. Hard and soft policies live here: top‑k, thresholds, softmax weights, or stochastic selection when exploration is desired.

### Map: Execute and Update

The only place where state is written. Emits outputs (perception calls, motor commands, logs) and produces the next contexts for each selected child. Also fuses new evidence, updates the scene graph and belief state, records policy outcomes in history, and advances the residual goal. Rule: everything reads the context; only Map writes it.

## The world state you actually have

At time $t$, the robot's belief is a triple $X_t = (G_t, B_t, H_{0:t})$:

- **$G_t$**: A typed scene graph with objects, their attributes and 6D poses, and relations like on_top_of, in, near, supports.

- **$B_t$**: Uncertainties and confidences from detectors, trackers, and pose estimators.

- **$H_{0:t}$**: History of tracks, successes and failures, operator corrections, and short logs that matter for scheduling and risk.

A natural‑language instruction $L$ compiles into a goal specification $\Phi$: predicates and constraints the world must satisfy, plus a small rule table that expresses affordances and preferences (for example, cylinders should be lifted with top suction; packets should be pinched at the side seam).

## Concrete example

Suppose the instruction is "pick the red cylinder on the tray and place it into the left bin."

**Partition** proposes the currently visible objects and their feasible affordance sites (top cap for suction, side faces for pinch).

**Summarize** computes item features: class posteriors from the base detector, 3D pose and top surface normal stability from depth, collision‑free approach angles, and the semantic compatibility of each object with "red cylinder." Also computes set features: the tray is crowded; only two candidates are red and cylindrical; the left bin is free.

**Compare** scores candidates as relevance − risk + progress: the red cylinder with a stable horizontal top cap and clear approach wins; the similar but orange cylinder loses relevance; the bag of packets loses affordance compatibility.

**Attend**, given a 25‑ms budget, selects one object to refine with an open‑vocabulary model and one grasp site to validate with a quick physics check.

**Map** dispatches the perception call on the selected ROI, updates the class posterior, commits the top‑slice suction plan, and produces the next context for the control loop to execute the approach and lift.

## Technical foundations

### The formal algebra

Let $N$ be nodes, $C$ contexts, $F$ features, $K$ scores, $W$ schedules, $O$ outputs. The five maps are:

- **P** (propose candidates): $P: N \times C \to \mathcal{P}(N)$
- **$U_{\text{item}}$** (summarize item): $U_{\text{item}}: N \times C \to F$
- **$U_{\text{set}}$** (summarize set): $U_{\text{set}}: \mathcal{P}(N) \times C \to F_{\text{set}}$
- **R** (score): $R: (F \times F_{\text{set}} \times C) \to K$
- **A** (schedule): $A: K \times C \to W$
- **M** (apply and update context): $M: (N, C, S \subseteq N, F, F_{\text{set}}, K, W) \to (O, \varphi)$

Here $S$ is the subset produced by Attend. The function $\varphi: S \to C$ supplies a per‑child next context. The runtime graph has vertices $(n, c)$ and edges $(n, c) \to (n', \varphi(n'))$ where $n' \in S$.

When visited nodes are keyed by a canonicalization of $(n, c)$ (for example, a stable hash of object id plus coarse pose bin and policy mode), this graph is a DAG during one traversal.

**Identity forms** make optionality precise:

- $P(n, c) = \{n\}$ when branching is disabled
- $U = \mathrm{id}$ when raw nodes are already features
- $R = \mathrm{const}$ when only an order from elsewhere is needed
- $A = \text{process-all}$ when no scheduling is needed
- $M = (\emptyset, c)$ when there are no outputs and the state does not change

### State, relevance, and history

Existing state is $X_t = (G_t, B_t, H_{0:t})$. Context $c$ is the slice of state the PCASM loop reads heavily each tick: budgets, planner flags, detector switches, seeds, and the current residual goal $\Delta\Phi$.

**Relevance** is a score inside Compare that ties the current goal to scene items:
$$
\mathrm{rel}(o \mid \Phi) = \sum_k w_k \, \mathbf{1}[o \; \text{participates in} \; \phi_k] \cdot \mathrm{compat}_k(o) - \lambda\,\mathrm{uncert}(o).
$$

Compatibility comes from language–vision grounding and uncertainty comes from $B_t$. History enters as priors and dampers: Summarize can include empirical grasp success per shape; Compare can penalize affordances that recently failed; Attend can shrink budgets for detectors that underperform on this scene.

### Scene graph deltas

Language $L$ produces a goal graph $G^\star$ or a predicate set $\Phi$. Progress requires aligning $G_t$ to $G^\star$ and measuring what is unsatisfied.

A simple scheme aligns nodes by cost:
$$
c_{ij} = \lambda_c\,d_{\mathrm{class}} + \lambda_p\,d_{\mathrm{pose}} + \lambda_s\,d_{\mathrm{shape}} + \lambda_a\,d_{\mathrm{attr}}.
$$

When relations matter, a Gromov–Wasserstein‑style alignment compares relational structures. The unmet predicates form $\Delta\Phi$; Compare rewards actions that reduce $\Delta\Phi$, and Map marks a predicate satisfied when an action completes.

### Language-grounded affordance routing

Instructions are oracles for affordance routing. There is no better signal in a production environment. Therefore we construct our primitive skill tree
from such data. An example rule table is:

```text
rule grasp:
  when class in {cylinder} and target=lift then action=grasp_top_slice
  when class in {packet, pouch} and target=lift then action=pinch_side
  default action=parallel_jaw_center
```

At runtime, language produces $\Phi$ and this rule table. Attend applies the router under budget; Map executes the chosen action and records its outcome.

### Cylinder vs packet

Pixels and depth show a red cylinder, a pouch, and a box on a tray. **Partition** proposes the three objects, plus candidate affordance sites (top cap for the cylinder, seams for the pouch, faces for the box).

**Summarize** includes per‑item features: class probabilities; top cap planarity from depth; suctions' clearance; seam continuity for the pouch; reachable approach vectors.

**Compare** favors the cylinder's top cap for a lift and penalizes the pouch for suction. **Attend** selects the cylinder and one pouch seam ROI for refinement.

**Map** triggers a quick open‑vocabulary confirmation on the ROI, locks in the top‑slice suction for the cylinder, and updates the context to execute the approach while keeping the pouch seam queued for later.

### Place into bin

After a successful lift, **Partition** proposes candidate placements in the left bin. **Summarize** computes bin free volume, surface normals, and stability scores.

**Compare** favors flat, empty subregions that yield satisfied predicates for in_bin(left). **Attend** selects one placement.

**Map** generates the motion segment, updates $G_t$ and $\Delta\Phi$, and logs success into history.

## Runtime modes

PCASM supports three practical modes without changing the algebra:

- **Lazy**: Processes one selected candidate per step; yields excellent responsiveness with minimal buffering
- **Batched**: Processes children in windowed chunks to stabilize ranking and amortize compute
- **Smart**: Enables set‑level Summarize and uncertainty‑aware Compare; Attend then schedules both sensing and acting under a concrete latency budget

## Implementation patterns

PCASM's five operations can be mapped to many existing algorithms:

| Algorithm | Partition | Compare | Attend | Summarize | Map |
|-----------|-----------|---------|--------|-----------|-----|
| **A* Search** | Generate neighbors from current node | Rank by f(n) = g(n) + h(n) | Select lowest f-score node from priority queue | Extract state info, path cost, and heuristic | Check if goal reached, return path |
| **Attention** | Generate all key-value pairs | Compute similarity scores between query and keys | Apply softmax to distribute focus | Extract key embeddings | Retrieve and weight values |
| **Beam Search** | Generate all possible next tokens/states | Score based on model probability | Keep top-k highest scoring candidates | Extract features for scoring | Return final sequence or state |
| **MCTS** | Generate legal moves/actions | Rank by UCB score: exploitation + exploration | Select highest UCB node | Extract visit counts and values | Perform rollout or return best action |
| **Caching** | Empty if cached, otherwise generate sub-problems | All equally important (1) | Process all uncached nodes | Generate cache key/hash | Compute or retrieve cached result |
| **Backprop** | Generate gradients for each parameter | Rank by gradient magnitude (optional) | Process all gradients, or prioritize larger ones | Calculate gradients based on loss | Update weights based on gradients |
| **DP** | Generate subproblems | All equally important (process in order) | Process all subproblems systematically | Extract subproblem state | Compute optimal solution from subproblems |

## Summary

PCASM provides a unified framework for real-time perception and manipulation under uncertainty. The five functionals—Partition, Summarize, Compare, Attend, Map—separate concerns cleanly while working together as a disciplined control loop. This structure enables robust behavior in complex, partially-observable environments where you must balance exploration, efficiency, and safety under hard real-time constraints.
