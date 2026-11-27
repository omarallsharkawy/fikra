# Map and client geometry

The page uses the HTML's 60px header, 13px authoritative node/link count,
56px coach, 12px coach radius, 18px graph card, 6px card padding, square drawing
viewport and compact category legend. The coach dismissal is stored on this
device per account/origin. Pending local deletions disappear from the graph
during the existing Undo window. Failed requests never masquerade as an empty
graph; typed errors offer retry, and an authoritative empty result offers capture.

Only repository nodes and edges are drawn. Geometry is a deterministic spring
and repulsion layout with stable ID-based seeding, damping, collision spacing,
centering and a cooling limit. For more than 120 nodes, a spatial grid bounds
local repulsion work; for more than 80 nodes, calculation runs in an isolate.
Dragging retains the chosen node while its neighbors settle. No HTML position
table, invented relationships, AI scores or category samples enter production.

Nodes use actual user category colors, or the muted token when no category is
assigned. Their radii follow `9 + degree × 6`, capped at 45 to keep a high-degree
node usable on a mobile viewport. Titles truncate by Unicode grapheme rather
than splitting Arabic combining marks or emoji. Full titles and selection
actions remain in accessibility semantics. Hit areas stay at least 44 physical
logical pixels regardless of camera zoom.

Drag a node to move it; drag the background to pan; pinch to zoom. A local
8px gesture threshold lets the canvas claim motion before the surrounding page
scroll. Long-press the graph for accessible zoom/fit buttons; equivalent semantic
actions are exposed to assistive technology. Selection is immediate and dims
unrelated nodes/edges with the HTML's 200ms opacity transition, disabled for
reduced motion. Opening a selected note keeps the existing GoRouter route.

## Comparison and verification

Four-mode captures are under `build/validation/redesign/{reference,after}/map-*`;
the combined comparison is `build/validation/redesign/map-comparison.png`.
These are real widget-tree captures with repository overrides containing only
test records, not native-device screenshots or production fallbacks. All normal
page geometry is compared at 398×650. Graph coordinates intentionally differ
from the HTML because its positions are mock data and the requested client must
calculate a real force layout. Legend entries include every actual assigned
category, including distinct categories that share a color; the prototype hides
one of its sample categories. Navigation follows the separately approved glass
variant. Native font rasterization can differ from browser screenshots.

`test/product/force_layout_test.dart` covers determinism, bounds, real-edge
attraction, empty/single-node graphs, fixed dragged nodes and an 800-node graph.
`test/product/redesign_graph_test.dart` exercises selection, drag, pinch, zoom,
fit, 44px targets, note navigation and error/empty recovery in both languages.
