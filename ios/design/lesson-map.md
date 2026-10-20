# All 191 lessons: picture and working

This map was made on 20 Oct 2026 from the web app's code (`web/src/curriculum/catalog.ts`, each lesson's imports from `explanations/diagrams/`, and each lesson's answer steps). It shows the picture each lesson uses on the web and the kind of working its answer needs. It's for grouping lessons by kit, not for designing them; each lesson still gets its own brief (see `README.md`). `~` means less certain.

**Working codes:**

| Code | Meaning |
|---|---|
| COUNT | count or read a picture |
| MC | pick one |
| NL | number-line hops or placement |
| PV | place value |
| COL | column add or take away |
| PP | partial products |
| LDIV | long division |
| SYNTH | synthetic division |
| FACT | one fact or a short line |
| READ | read a clock, ruler, scale or graph |
| FRAC | a fraction rewritten or worked |
| FRAC-CD | fractions over one bottom |
| RATIO | ratio, rate or percent |
| DECPT | moving the point |
| ORDER | order of operations, or substitute and evaluate |
| EQ | an equation line by line |
| EXPR | rewrite an expression |
| FORMULA | numbers into a formula |
| COORD | an (x, y) answer |

```
k-count20 | K | Count to 20 | early-k/counting | COUNT
k-write | K | Write numbers 0 to 20 | early-k/numerals | MC
k-teens | K | Teen numbers | early-k/frames | PV
k-compare | K | More, less or the same | early-k/groups | MC
k-tens | K | Count by tens to 100 | early-k/counting | COUNT
k-add | K | Adding within 10 | number-line | NL
k-sub | K | Taking away within 10 | early-k/groups | COUNT
k-story | K | Story problems within 10 | early-k/groups | MC ~
k-bonds | K | Number bonds | early-k/bond | COUNT
k-make10 | K | Make 10 | early-k/frames | COUNT
k-shapes | K | Flat shapes | early-k/shapes | MC
k-solids | K | Solid shapes | early-k/solids | MC
k-length | K | Longer and shorter | early-k/lengths | MC
k-sort | K | Sort and count | early-k/sort | MC
g1-tensones | 1 | Tens and ones | early-g1/blocks | PV
g1-compare | 1 | Compare two-digit numbers | early-g1/blocks | MC
g1-tenmore | 1 | 10 more, 10 less | early-g1/blocks+chart | PV
g1-add20 | 1 | Add within 20 | number-line | NL
g1-ten | 1 | Make a ten to add | early-k/frames | FACT
g1-three | 1 | Add three numbers | early-g1/three | FACT
g1-sub20 | 1 | Subtract within 20 | number-line | NL
g1-missing | 1 | Missing numbers | number-line | NL
g1-addtens | 1 | Add tens to a number | early-g1/blocks | PV
g1-time | 1 | Time to the hour and half hour | early-g1/clock | READ
g1-measure | 1 | Measure length | early-g1/measure | READ
g1-halves | 1 | Halves and fourths | early-g1/parts | MC
g1-picgraph | 1 | Picture graphs | early-g1/data | MC
g1-tally | 1 | Tally charts | early-g1/data | COUNT
g2-hundreds | 2 | Hundreds, tens and ones | early-g2/blocks | PV
g2-skip | 2 | Skip counting | early-g2/lines | NL
g2-evenodd | 2 | Even and odd | early-g2/counting | MC
g2-regroup | 2 | Adding with regrouping | area-model/blocks | COL
g2-subregroup | 2 | Subtracting with regrouping | early-g2/blocks | COL
g2-within1000 | 2 | Add and subtract within 1000 | early-g2/lines | PV
g2-coins | 2 | Name the coin | early-g2/coins | MC
g2-money | 2 | Counting money | early-g2/counting | COUNT ~
g2-time5 | 2 | Time to 5 minutes | early-g2/measure | READ
g2-measure | 2 | Inches and centimeters | early-g2/measure | READ
g2-estimate | 2 | Estimate length | early-g2/estimate | MC
g2-bargraph | 2 | Bar graphs | early-g2/measure | READ
g2-lineplot | 2 | Line plots | early-g2/lineplot | READ
g2-arrays | 2 | Arrays | early-g2/counting | FACT
g2-solids | 2 | Faces, edges and corners | early-k/solids | MC
g2-shares | 2 | Halves, thirds and fourths | early-g2/shares | MC
g3-facts | 3 | Multiplication facts | early-g3/array | FACT
g3-divfacts | 3 | Division facts | early-g3/array | FACT
g3-split | 3 | Multiply by breaking apart | area-model/grid | PP
g3-mult10 | 3 | Multiply by multiples of 10 | early-g3/array | FACT
g3-twostep | 3 | Two-step word problems | tape | FACT
g3-round | 3 | Rounding to 10 and 100 | number-line | NL
g3-addsub | 3 | Add and subtract within 1000 | number-line | NL
g3-unitfrac | 3 | Unit fractions | tape | FRAC
g3-fracline | 3 | Fractions on a number line | early-g3/frac-line | NL
g3-fraccompare | 3 | Comparing fractions | tape | MC
g3-area | 3 | Area by counting squares | early-g3/squares | FACT
g3-perim | 3 | Perimeter | early-g3/perimeter | FACT
g3-elapsed | 3 | Elapsed time | early-g3/timeline | NL
g3-mass | 3 | Grams and kilograms | early-g3/scale | READ
g3-liters | 3 | Liters | early-g3/jug | READ
g3-graphs | 3 | Scaled picture and bar graphs | early-g1/data | READ
g3-lineplot | 3 | Line plots with halves and fourths | early-g2/lineplot | READ
g3-quads | 3 | Quadrilaterals | early-g3/quads | MC
g4-placevalue | 4 | Place value and rounding | early-g4/place-value | PV
g4-addsub | 4 | Add and subtract big numbers | early-g4/columns | COL
g4-partial | 4 | Multiply big numbers | area-model/grid | PP
g4-mult2x2 | 4 | Two-digit times two-digit | area-model/grid | PP
g4-divide | 4 | Dividing with remainders | area-model/grid | LDIV
g4-factors | 4 | Factors and multiples | early-g4/factor-rects | FACT
g4-equiv | 4 | Equivalent fractions | tape | FRAC
g4-fraccompare | 4 | Comparing fractions | tape | FRAC-CD
g4-likefrac | 4 | Adding like fractions | tape | FRAC
g4-mixed | 4 | Adding mixed numbers | early-g4/mixed-bars | FRAC
g4-fracwhole | 4 | Fraction times a whole number | tape | FRAC
g4-dec | 4 | Tenths and hundredths | early-g4/hundredths | PV
g4-deccompare | 4 | Comparing decimals | early-g4/hundredths | MC
g4-convert | 4 | Converting measurements | early-g4/double-line | RATIO
g4-lineplot | 4 | Line plots with fractions | early-g2/lineplot | READ
g4-area | 4 | Area and perimeter | area-model/grid | FORMULA
g4-lines | 4 | Points, lines, rays and angles | early-g4/figures | MC
g4-angles | 4 | Angles add up | angle | FACT
g4-symmetry | 4 | Lines of symmetry | early-g4/fold | MC
g5-mult2 | 5 | Multiply two-digit numbers | area-model/build | PP
g5-divide | 5 | Long division | area-model/build | LDIV
g5-order | 5 | Order of operations | order | ORDER
g5-pow10 | 5 | Multiply by 10, 100, 1000 | number-line/decimal-shift | DECPT
g5-round | 5 | Rounding decimals | number-line | PV
g5-adddec | 5 | Adding decimals | early-g4/columns | COL
g5-multdec | 5 | Multiplying decimals | area-model/grid | DECPT
g5-divdec | 5 | Dividing by a decimal | early-g4/double-line | DECPT
g5-improper | 5 | Mixed numbers to fractions | tape | FRAC
add | 5 | Adding fractions | tape | FRAC-CD
sub | 5 | Subtracting fractions | tape | FRAC-CD
mix | 5 | Adding and subtracting | tape | FRAC-CD
g5-fracof | 5 | Fraction of a number | tape | RATIO
g5-multfrac | 5 | Multiplying fractions | frac-grid | FRAC
g5-unitdiv | 5 | Dividing by a unit fraction | tape | FRAC
g5-volume | 5 | Volume of a box | box3d | FORMULA
g5-units | 5 | Converting units | tape | RATIO
g6-ratio | 6 | Equivalent ratios | tape | RATIO
g6-rate | 6 | Unit rates | tape | RATIO
g6-pctof | 6 | Percent of a number | tape | RATIO
g6-pctwhole | 6 | Find the whole | tape | RATIO
g6-divide | 6 | Dividing fractions | tape | FRAC
g6-lcm | 6 | Least common multiple | number-line | NL
g6-gcf | 6 | Factor out the GCF | area-model/grid | EXPR
g6-numline | 6 | Distance on a number line | number-line | NL
g6-expo | 6 | Exponents and order | algebra/boxes | ORDER
g6-eval | 6 | Evaluate expressions | tape | ORDER
g6-onestep | 6 | One-step equations | algebra/balance | EQ
g6-tri | 6 | Area of a triangle | area-model/grid | FORMULA
g6-trap | 6 | Area of a trapezoid | area-model/grid | FORMULA
g6-mean | 6 | Find the mean | bars | FORMULA
g7-prop | 7 | Solve a proportion | tape | RATIO
g7-scale | 7 | Scale drawings | tape | RATIO
g7-discount | 7 | Discounts, tax and tips | tape | RATIO
g7-pctchange | 7 | Percent change | tape | RATIO
g7-addint | 7 | Adding integers | number-line | NL
g7-subint | 7 | Subtracting integers | number-line | NL
g7-mulint | 7 | Multiplying and dividing integers | number-line | NL
g7-eq | 7 | Two-step equations | algebra/balance | EQ
g7-distribute | 7 | Distribute and combine | area-model/grid | EXPR
g7-circum | 7 | Circumference | circle | FORMULA
g7-circarea | 7 | Area of a circle | circle | FORMULA
g7-angles | 7 | Complementary and supplementary | angle | FORMULA
g7-prob | 7 | Probability | marbles | FRAC
g8-exp | 8 | Exponent rules | algebra/chips | EXPR
g8-sci | 8 | Scientific notation | number-line/decimal-shift | DECPT
g8-roots | 8 | Square and cube roots | area-model/grid + box3d | FACT
g8-func | 8 | Evaluate a function | plane | ORDER
g8-slope | 8 | Slope from two points | plane | FORMULA
g8-intercept | 8 | Slope-intercept form | plane | EXPR
g8-both | 8 | Variables on both sides | algebra/balance | EQ
g8-system | 8 | Systems by substitution | plane | EQ
g8-pyth | 8 | Pythagorean theorem | right-triangle | FORMULA
g8-leg | 8 | Find a missing leg | right-triangle | FORMULA
g8-cyl | 8 | Volume of a cylinder | cylinder | FORMULA
g8-cone | 8 | Volume of a cone | cylinder | FORMULA
g8-translate | 8 | Translations | plane | COORD
g8-tri | 8 | Angles in a triangle | triangle-angles | FORMULA
g9-multistep | 9 | Multi-step equations | algebra/balance | EQ
g9-elim | 9 | Systems by elimination | algebra/balance | EQ
g9-twopoint | 9 | Line through two points | plane | EXPR
g9-negexp | 9 | Zero and negative exponents | algebra/chips | EXPR
g9-growth | 9 | Exponential growth | plane | FORMULA
g9-radical | 9 | Simplify square roots | area-model/grid | EXPR
g9-polyadd | 9 | Add and subtract polynomials | algebra/terms | EXPR
g9-foil | 9 | Multiply binomials | area-model/grid | EXPR
g9-gcf | 9 | Factor out the GCF | area-model/grid | EXPR
g9-factor | 9 | Factoring quadratics | area-model/grid | EXPR
g9-solvefactor | 9 | Solve by factoring | plane | EQ
g9-quadform | 9 | The quadratic formula | plane | FORMULA
g9-median | 9 | Find the median | bars | FORMULA
g10-mid | 10 | Midpoint | plane | COORD
g10-perp | 10 | Perpendicular slopes | plane | FORMULA
g10-dist | 10 | Distance between points | plane | FORMULA
g10-circle | 10 | Equation of a circle | plane | COORD
g10-polygon | 10 | Angles in a polygon | polygon-split | FORMULA
g10-exterior | 10 | Exterior angle | triangle-angles | FORMULA
g10-similar | 10 | Similar triangles | similar | RATIO
g10-special | 10 | Special right triangles | right-triangle | FORMULA
g10-trig | 10 | Sine, cosine and tangent | right-triangle | FRAC
g10-sector | 10 | Area of a sector | circle | FORMULA
g10-arc | 10 | Arc length | circle | FORMULA
g10-surface | 10 | Surface area of a box | box3d | FORMULA
g10-pyramid | 10 | Volume of a pyramid | box3d | FORMULA
g11-seq | 11 | Arithmetic sequences | number-line | FORMULA
g11-geo | 11 | Geometric sequences | plane | FORMULA
g11-ratexp | 11 | Rational exponents | algebra/chips | EXPR
g11-expeq | 11 | Exponential equations | algebra/chips | EQ
g11-log | 11 | Evaluating logarithms | plane | ORDER
g11-evalpoly | 11 | Evaluate a polynomial | plane | ORDER
g11-synth | 11 | Synthetic division | algebra/terms | SYNTH
g11-compose | 11 | Composing functions | algebra/boxes | ORDER
g11-inverse | 11 | Inverse functions | plane | EXPR
g11-vertex | 11 | Vertex of a parabola | plane | COORD
g11-radical | 11 | Radical equations | area-model/grid | EQ
g11-complex | 11 | Multiplying complex numbers | area-model/grid | EXPR
g11-comb | 11 | Combinations | marbles | FORMULA
g12-rad | 12 | Degrees to radians | circle | FRAC
g12-deg | 12 | Radians to degrees | circle | FORMULA
g12-unit | 12 | Unit circle values | circle | FORMULA
g12-limit | 12 | Limits by factoring | plane | EXPR
g12-power | 12 | Power rule | algebra/terms | EXPR
g12-polyd | 12 | Derivative of a polynomial | algebra/terms | EXPR
g12-tangent | 12 | Slope of a tangent line | plane | EXPR
g12-chain | 12 | Chain rule | algebra/boxes | EXPR
g12-anti | 12 | Antiderivatives | algebra/terms | EXPR
g12-defint | 12 | Definite integrals | plane | FORMULA
g12-series | 12 | Arithmetic series | algebra/pairs | FORMULA
g12-vecmag | 12 | Vector length | plane | FORMULA
g12-dot | 12 | Dot product | plane | FORMULA
```
