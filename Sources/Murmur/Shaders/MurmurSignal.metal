// The Signal pack. Six thinking indicators, and this is the family that carries
// the product's metaphor: ORDER EMERGING FROM NOISE. Every other pack in Murmur
// is a material doing what materials do. These six are a mind doing what a mind
// does, said in material.
//
//   ms_murmuration  the namesake. A flock as ONE SOFT MASS: a density sheet
//                   folded by its own turn, seen edge on. Never a bird.
//   ms_loom         warp and weft interference resolving into cloth, and easing
//                   off again. The cloth is the interference, not drawn thread.
//   ms_cipher       a latent field that is always there, lit only where a slow
//                   attention lowers the threshold and lets meaning surface.
//   ms_tuning       static finding the station: a broadband field narrowing onto
//                   one coherent line. Coherent is rest; the hiss never leaves.
//   ms_current      impulses travelling a soft conducting medium, felt as light
//                   moving through it. No wires, no nodes, no junction dots.
//   ms_veil         three translucent scrims sliding at different rates over a
//                   brighter thing behind them, which stays almost legible.
//                   Parallax as depth of thought.
//   ms_echo         an irregular mass answered by its own past: ghosts displaced
//                   along a heading, each later, softer and dimmer. No rings.
//   ms_glyph        almost-writing. Strokes struck by a wandering hand that
//                   begin dissolving before they finish forming. No letters.
//
// WHAT THIS FAMILY IS NOT. The inspiration piece these indicators replace is a
// fibonacci dot sphere, and the single easiest way to fail here is to draw
// individuals: a bird, a node, a mote, a star. There is not one discrete mark in
// this file. Everything on screen is a DENSITY evaluated at that pixel, and
// where a species wants to say "many", it says it with the statistics of a mass,
// never with a countable thing. ms_murmuration is the acid test: if a single
// bird is ever resolvable the shader is wrong, however well it reads otherwise.
//
// THE VERBS ARE FLOW AND SETTLE. Nothing here pulses its brightness to say it is
// alive. Time enters where the coordinates are READ -- an advected domain, a
// travelling phase, a rotating frame, a narrowing passband -- so what the eye
// sees is material moving, not a light being turned up and down. One species has
// a slow structural cycle -- the loom's tautness, which resolves cloth and eases
// it off again -- and that cycle moves the WEAVE, not the luminance: its mean
// brightness barely changes across the whole beat, which is the difference
// between a loom and a blinking light.
//
// THE TEMPO, which was reset once on device. These are THINKING indicators, and
// the first tune held them at the tempo of an ambient card: correct for a
// surface a person lives beside, one notch too still for a thing that is meant
// to say ATTENTION. So every internal rate in this file was lifted, and the
// rule for how much is the one worth carrying: a species' CARRIER -- the motion
// that is the idea, the flock's travel, the cloth crossing the loom, the
// attention's traverse, the impulse's run -- went up about twice, while its
// DETAIL -- the grain, the drape, the boil of the noise underneath -- went up
// about half again. Lifting both equally makes a field busier rather than
// faster; lifting the carrier harder makes it move without adding anything to
// look at, which is the difference between active and stormy. `speed` still
// means "the designed tempo" at 1.0. What changed is what that tempo is.
//
// THE CIRCLE. These mount at 20 to 300 points inside a Circle clip. The view
// clips; the shader must never lean on that. Every function brings its light all
// the way down to pure ink by a uv radius of about 0.45, well inside the clip at
// 0.5, so no form is ever sliced by an edge it cannot see. That is what
// ms_containment is for, and all six call it.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal VERBATIM under an ms_
// prefix, the way the house has done it before. Copied, unchanged except for the
// name:
//
//   ms_hash, ms_grad3, ms_noise3, MS_ROT, ms_fbm3,
//   ms_hash1, ms_vnoise1, ms_fbm1,
//   ms_srgb_to_linear, ms_linear_to_srgb, ms_linear_to_oklab,
//   ms_oklab_to_linear, ms_lch, MSPalette, ms_palette, ms_shade,
//   ms_out, ms_knee, ms_settle_law (pv_exhale_law)
//
// Their comments come with them: the reasoning is the part worth carrying. What
// is deliberately NOT copied: fl_noised3 and fl_fbmd3, the derivative-carrying
// pair, because nothing in this pack lights a surface by its slope -- the two
// species that want a highlight (loom, tuning) have closed-form phases and can
// differentiate them by hand for free. Copying thirty-two hashes an octave that
// nobody calls would only leave dead code behind a prefix. fl_edge is not copied
// either: its slightly tall ellipse is the right dissolve for a screen and the
// wrong one for a circle, so ms_containment below is the radial equivalent,
// written rather than adapted so the reason stays on the page.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's or FieldPackPour.metal's,
// verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint ms_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 ms_grad3(int3 c) {
    uint h = ms_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float ms_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(ms_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(ms_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(ms_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(ms_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(ms_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(ms_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(ms_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(ms_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse.
/// Without it every octave stacks on the same lattice axes and the field grows a
/// visible plaid.
constant float3x3 MS_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

static float ms_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * ms_noise3(q);
        amp *= gain;
        q = lacunarity * (MS_ROT * q);
    }
    return value;
}

static inline float ms_hash1(float cell, float lane) {
    return float(ms_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float ms_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(ms_hash1(i, lane), ms_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float ms_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * ms_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

static inline float3 ms_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 ms_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 ms_linear_to_oklab(float3 c) {
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    float l_ = pow(max(l, 0.0), 1.0 / 3.0);
    float m_ = pow(max(m, 0.0), 1.0 / 3.0);
    float s_ = pow(max(s, 0.0), 1.0 / 3.0);
    return float3(0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
                  1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
                  0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_);
}

static inline float3 ms_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 ms_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the tone the indicator wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MSPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MSPalette ms_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = ms_linear_to_oklab(ms_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = ms_linear_to_oklab(ms_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MSPalette p;
    p.s0 = ink;
    p.s1 = ms_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = ms_lch(L, C, h);
    p.s3 = ms_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; ms_out does the encoding.
static float3 ms_shade(MSPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return ms_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 ms_out(float3 linearRGB, float2 pixel) {
    float3 c = ms_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float ms_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// THE SETTLE LAW, copied from FieldPackPour.metal's pv_exhale_law. Motion
/// stated as a SPEED, position drawn from that speed's closed-form INTEGRAL:
///
///   v(tau) = hold + (1 - hold) e^(-k tau),   k = 3 / settleTime
///   D(tau) = hold tau + (1 - hold) (1 - e^(-k tau)) / k
///
/// k is 3 / settleTime rather than 1 / settleTime so that the dial means what it
/// says: at tau = settleTime the speed is within five per cent of the hold,
/// which is the instant a person would call it stopped. D is the exact integral
/// of v, so the field's position at any t is the position the animation would
/// have reached -- no frame has to remember the last one, and a screenshot rig
/// or a scrubbed slider lands exactly where the animation would have been. The
/// floor is not zero: a field that stops dead is a frozen image; a field that
/// keeps a whisper of drift is a held breath. Returns (v, D, e), where e is the
/// still-moving fraction.
static inline float3 ms_settle_law(float tau, float settleTime) {
    const float HOLD = 0.055;
    float E = max(settleTime, 0.50);
    float k = 3.0 / E;
    float e = exp(-k * max(tau, 0.0));
    float v = HOLD + (1.0 - HOLD) * e;
    float D = HOLD * max(tau, 0.0) + (1.0 - HOLD) * (1.0 - e) / k;
    return float3(v, D, e);
}

// MARK: - The pack's own four tools
//
// Not copied: these four are this pack's, and they exist so that the six species
// share a silhouette, a light law and a finish rather than each inventing one.

/// THE CONTAINMENT. fl_edge's job, done for a circle instead of a screen.
///
/// The view clips these indicators to a Circle at length(uv) = 0.5, and a clip
/// is a hard edge: any form still carrying light when it arrives is sliced, and
/// a sliced organic form is the most obvious tell that a field was built for a
/// rectangle. So every species dissolves to PURE INK before the rim, which also
/// gives the indicator a soft silhouette of its own and means it would read
/// correctly with no clip at all. The clip is a guarantee, not the design.
///
/// `reach` is where the fall begins, on the doubled radius (1.0 is the clip).
/// The 0.31 span puts full ink at reach + 0.31, so the callers' 0.56 to 0.62 all
/// land between a uv radius of 0.435 and 0.465: inside the clip with room to
/// spare, and wide enough that the falloff itself is never a visible ring.
static inline float ms_containment(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    return 1.0 - smoothstep(reach, reach + 0.31, r);
}

/// THE VALUE HIERARCHY, as one curve, and it replaces the dim ceiling this pack
/// used to hold.
///
/// The old law kept every span at or under about 0.84 so nothing reached the
/// rail's pale specular -- a deliberate ambient restraint, and on device it was
/// exactly wrong. These are small objects in a chat UI, not surfaces someone
/// lives beside, and a cell whose brightest pixel is rust is a cell nobody can
/// parse. Three tiers or it fails: ink ground, amber body, CREAM PEAKS.
///
/// One number gets all three by spending the rail unevenly. The bottom
/// seventy-eight per cent of the energy is compressed into the rail's first
/// seventy-two, which is the whole amber body from shadow to tone, so most of
/// the picture is warm and readable and none of it is near white. The last
/// twenty-two per cent of the energy is spent on the rail's last twenty-eight,
/// where the specular lives, so only the figure's key structure goes cream --
/// and when it goes it goes decisively rather than creeping.
///
/// The join is smoothed over a fifth of the range, because a slope kink in a
/// map this shallow shows up as a contour line in a smooth field. It is the
/// same reason ms_shade eases its own segment joins.
///
/// What this asks of every species: normalise so the figure's SPINE reaches
/// about 1.0 while its body sits between 0.35 and 0.7. The brightness tuning
/// that used to live in per-species spans now lives in that normalisation,
/// which is the more honest place for it -- a species should know how bright
/// its own spine is.
static inline float ms_tier(float e) {
    float x = clamp(e, 0.0, 1.0);
    const float K = 0.78;
    float body = (x / K) * 0.72;
    float peak = 0.72 + ((x - K) / (1.0 - K)) * 0.28;
    return mix(body, peak, smoothstep(K - 0.10, K + 0.10, x));
}

/// THE ONE PLACE ENERGY BECOMES LIGHT. All six species compute a density in
/// 0...1 and hand it here, which is most of what keeps the family reading as one
/// family: there is exactly one relationship between how much material is at a
/// pixel and how bright and how warm that pixel is, and no species invents its
/// own.
///
/// `base` and `span` choose the species' band on the rail. A zero base means an
/// empty pixel is the ink itself, to the bit, so the field dissolves into its
/// pill with no seam. Spans stay at or under about 0.84 on purpose: the rail's
/// third segment starts at 0.78 and runs to a pale specular, and a thinking
/// indicator that lives in the specular is a lamp. Peaks may touch it; bodies
/// may not. That is the house's dim ceiling, written as a number.
///
/// `glow` is the presence dial and it enters twice, both times where it cannot
/// lie: it scales the energy BEFORE the rail walk, so a lower setting walks less
/// far and therefore reads cooler and deeper rather than merely faded, and it
/// scales the emission on top. At glow = 1 the first term is the identity. At
/// glow = 0 a third of the energy survives, because an indicator that can be
/// switched off by a dial is a bug and not a dial.
///
/// The knee before the rail walk, and not a clamp, because a clamp is where
/// these species would go wrong in the same way: several of them build an energy
/// that can pass 1 in their bright places, and clamping turns those places into
/// FLAT plateaus of identical colour with a visible contour around them. The
/// knee compresses the same overshoot asymptotically, so a hot crossing or a
/// crest of an impulse keeps its shape instead of becoming a patch.
static inline float3 ms_lit(MSPalette pal, float e, float glow,
                            float base, float span, float emis) {
    float G = max(glow, 0.0);
    // The knee sits at 0.92 rather than 0.82 now. At 0.82 it compressed the top
    // of the range away before ms_tier could spend it, so a spine normalised to
    // reach one arrived at the rail already flattened and its peak came out tone
    // rather than cream: the knee was quietly enforcing the very ceiling this
    // pass exists to lift. It still catches genuine overshoot.
    float en = clamp(ms_knee(max(e, 0.0) * (0.35 + 0.65 * G), 0.92), 0.0, 1.0);
    float tRail = clamp(base + span * ms_tier(en), 0.0, 1.0);
    float3 col = ms_shade(pal, tRail);
    // Emission is gated to the specular now, not to the tone: the rail reaches
    // the top routinely, and emission from the whole amber body would put the
    // ground back up and flatten the very hierarchy ms_tier just built.
    return col * (1.0 + emis * G * smoothstep(0.72, 1.0, tRail));
}

/// A rotation, written out because three of the six species live in a frame that
/// is turning, and `ms_rot(uv, a)` at the call site says so.
static inline float2 ms_rot(float2 v, float a) {
    float c = cos(a), s = sin(a);
    return float2(c * v.x - s * v.y, s * v.x + c * v.y);
}

/// THE ANTI-ALIAS GATE. Two species put full amplitude on a chosen frequency --
/// the loom's pitch and the tuning's passband -- and a chosen frequency has a
/// floor: below about two pixels a cycle it stops being a form and becomes
/// moire, which at 20 pt with the form scale wound down is a real setting and
/// not a theoretical one. It matters here and not in the fBm species because an
/// fBm's top octave carries an eighth of the amplitude and its aliasing is a
/// whisper, while a passband's chosen octave carries ALL of it, and the shimmer
/// that comes back reads as exactly the thing this family may never show: motes.
///
/// `cycles` is the structure's wavenumber in radians per uv unit, and the frame
/// gives the rest: one uv unit is min(size) points, which is min(size) *
/// pixelScale pixels. The gate returns 1 while the structure is comfortably
/// resolved and eases its CONTRIBUTION to nothing as it approaches a third of a
/// cycle per pixel, so structure that can no longer be drawn honestly becomes
/// its own soft average instead of a sparkle.
static inline float ms_aa(float cycles, float2 size, float pixelScale) {
    float px = max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0);
    float perPixel = max(cycles, 0.0) / (6.2831853 * px);
    return 1.0 - smoothstep(0.16, 0.36, perPixel);
}

/// THE STATE READ, shared by all eight species.
///
/// Two of the five states get an in-shader design; the rest are carried by the
/// per-state parameter sets the Swift layer interpolates, which is the right
/// division of labour -- a dial change is a dial change and does not belong in
/// a branch here.
///
/// SUCCESS is this family's moment, and the family's own physics for it is THE
/// PATTERN COMPLETES. Every one of these species is reaching for an order it
/// never quite attains: the flock's fold, the loom's cloth, the station, the
/// almost-word. For one breath at the top of a success, it arrives. `complete`
/// is that breath: in over about a quarter of a second, out over the rest of
/// 1.2, on a curve whose ends are flat so nothing snaps. `settled` is what is
/// left afterwards and holds for as long as the state does -- the field a
/// little brighter and a little more ordered than it was, the way a thing that
/// has just succeeded looks.
///
/// The light in a success is NOT an overlay. Every species multiplies its own
/// energy by (1 + complete), which brightens exactly what is already there and
/// leaves the dark dark: the surge travels through the species' own structure
/// because it IS the species' own structure, scaled. A white wash over the top
/// would have been two lines of code and a different product.
///
/// RESPONDING is decisive drive: the search stops casting about and acquires a
/// direction, continuously, for as long as the state holds. `drive` ramps in
/// over half a second so entering the state is a lean and not a jolt.
struct MSState {
    float complete;   // success: the arrival, one breath
    float settled;    // success: what is left after it
    float drive;      // responding: directional urgency, held
};

static MSState ms_state(float stateIndex, float stateTau) {
    MSState o;
    o.complete = 0.0; o.settled = 0.0; o.drive = 0.0;
    float tau = max(stateTau, 0.0);
    if (stateIndex > 2.5 && stateIndex < 3.5) {
        float a = clamp(tau / 1.20, 0.0, 1.0);
        // In over about 0.36 s, out over the remaining 0.8. The rise was 0.24 s
        // in the first cut and at 30 fps that is seven frames, which reads as a
        // strobe rather than as an arrival. An arrival wants to be seen arriving.
        o.complete = smoothstep(0.0, 0.30, a) * (1.0 - smoothstep(0.36, 1.0, a));
        o.settled  = smoothstep(0.30, 1.05, a);
    } else if (stateIndex > 1.5 && stateIndex < 2.5) {
        o.drive = smoothstep(0.0, 0.55, tau);
    }
    return o;
}

/// THE FLOURISH CLOCK, and it is the pack's play mechanism.
///
/// Every species here performs ONE gesture: a thing the material does now and
/// then and then lets go of. The clock says when, and the three rules it exists
/// to keep are all in its arithmetic.
///
/// APERIODIC, NEVER A METRONOME. Time is cut into 6.5 second slots and each slot
/// holds exactly one gesture, but WHERE in its slot the gesture falls is hashed
/// per slot. The interval between two onsets is therefore the slot length plus
/// the difference of two independent jitters -- about four to nine seconds, with
/// no two gaps the same and nothing for the eye to lock onto. A gesture on a
/// timer stops being play and becomes a tick.
///
/// DETERMINISTIC. The slot index is floor(t / SLOT) and everything else is a
/// hash of it, so any t at all renders the correct frame: a screenshot rig, a
/// scrubbed slider and a resumed app all agree, exactly as the rest of the file
/// does. There is no state between frames anywhere in this pack and play does
/// not get to be the exception.
///
/// NOTHING SNAPS. The envelope is sin^2(pi u), which is zero with zero slope at
/// both ends. It does not begin, it arrives; it does not stop, it finishes. A
/// linear ramp or a smoothstep to a hold would both put a corner in the motion,
/// and a corner is the difference between a flourish and a glitch.
///
/// The gesture starts between 1.15 and 3.35 seconds into its slot and lasts
/// between 1.6 and 3.0, so it always finishes inside its own slot and two
/// gestures never overlap.
///
/// Returns (envelope, progress, a per-gesture random, the slot index). The
/// random is what lets each occurrence differ -- which way the flock splits,
/// which thread is pulled, which repetition comes back close -- so the play is
/// never the same twice either.
static float4 ms_flourish(float t, float lane) {
    const float SLOT = 6.5;
    float slot = floor(t / SLOT);
    float local = t - slot * SLOT;
    float start = 1.15 + 2.20 * ms_hash1(slot, lane);
    float dur   = 1.60 + 1.40 * ms_hash1(slot + 811.0, lane);
    float u = (local - start) / dur;
    float sn = sin(3.14159265 * clamp(u, 0.0, 1.0));
    float env = (u <= 0.0 || u >= 1.0) ? 0.0 : sn * sn;
    return float4(env, clamp(u, 0.0, 1.0), ms_hash1(slot + 1607.0, lane), slot);
}

/// A VEIN: distance to a gently bending line, tapered to nothing at both ends.
/// The delta in ms_current is four of these and nothing else. A line with an end
/// is the cheapest nameable figure there is, and unioning a few at different
/// angles is a branching system a viewer can trace with a finger, which no
/// amount of ridged noise ever was.
static inline float ms_vein(float2 p, float ang, float bend, float freq,
                            float phase, float halfw, float len) {
    float2 r = ms_rot(p, ang);
    float d = abs(r.y - bend * sin(r.x * freq + phase));
    // Thick at the root, gone by the tip, and starting cleanly rather than
    // arriving from off-frame: a branch has two ends and both of them matter.
    float grow = smoothstep(-0.02, 0.09, r.x);
    float end  = 1.0 - smoothstep(len * 0.55, len, r.x);
    float w = halfw * (0.45 + 0.55 * end);
    return (1.0 - smoothstep(w * 0.30, w, d)) * grow * end;
}

/// A PANE: the signed distance to a rounded rectangle, for ms_veil's sheets.
/// Translucent layers only read as layers if they have EDGES; three noise fields
/// with soft silhouettes read as one cloud, which is what the veil was.
static inline float ms_pane(float2 p, float2 c, float ang, float2 halfSize, float rad) {
    float2 q = abs(ms_rot(p - c, ang)) - (halfSize - rad);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rad;
}

/// The house finish, shared: ink underneath, the field composited into it by the
/// containment, the same knee the route curtain puts on its surface colour, and
/// the dither last. Every species ends on this line.
static inline half4 ms_finish(float3 field, float3 inkLin, float containment,
                              float2 position, float pixelScale) {
    float3 rgb = mix(inkLin, field, containment);
    rgb = float3(ms_knee(rgb.r, 0.90), ms_knee(rgb.g, 0.90), ms_knee(rgb.b, 0.90));
    return ms_out(rgb, position * pixelScale);
}

// MARK: - 1. Murmuration

// MURMURATION. The namesake, and the one that has to be right.
//
// A murmuration is not a lot of birds. From any distance a person actually
// watches one it is a SURFACE: a sheet of density that folds and rolls, thick
// where it turns edge on and almost transparent where it turns its face to you.
// That thickening is the whole picture and none of it is countable. So the flock
// here is a sheet, and it is a sheet all the way down: there is no population in
// the code to accidentally resolve.
//
// HOW THE SHEET IS MADE. A signed noise field's zero level is a surface. Take
// exp(-|n| / thickness) of it and that surface becomes a soft slab of density
// with no edge anywhere: full along the level set, fading smoothly to nothing
// either side. The slab wanders through three dimensions, so a two-dimensional
// slice of it is a set of soft bands that split, merge and vanish -- which is
// what a folded sheet looks like from the ground. `cohesion` is that thickness:
// 0.46 is a diffuse haze of a flock, 0.13 a tight one with real creases in it.
// Nothing in the range resolves an individual because there are none.
//
// HOW IT TURNS. The bank is two incommensurate slow sines, about a minute and
// about thirty five seconds, so the mass leans one way and then another and the
// eye never learns the period. The ROLL is the interesting half: the rotation
// angle is LARGER at the centre than at the rim, so the sheet is sheared as it
// banks, and a sheared sheet folds over itself. That fold costs one rotation
// rather than a second noise field, and it is the honest physics -- a flock
// folds because its inside turns faster than its outside. The single warp field
// is applied along the TANGENT of that turn, which is the direction the material
// is actually being dragged.
//
// THE SKY is the dusk the mass is seen against: two octaves, very broad, very
// dim, thinning where the flock is dense because the flock is in front of it. It
// is a field and not a gradient, which matters twice: a linear ramp would band
// in an eight bit dark, and a sky is not a ramp.
[[ stitchable ]] half4 ms_murmuration(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float flock    = clamp(c0, 0.0, 1.0);   // how much material is in the air
    float turn     = clamp(c1, 0.0, 1.0);   // how hard the mass banks and rolls
    float cohesion = clamp(c2, 0.0, 1.0);   // sheet thickness: haze to crease
    float sky      = clamp(c3, 0.0, 1.0);   // the dusk behind it

    // THE BANK.
    MSState st = ms_state(stateIndex, stateTau);

    float bank = turn * (0.62 * sin(t * 0.214) + 0.31 * sin(t * 0.362 + 1.7));

    // THE ROLL. 0.26 is roughly where the mass's own body ends, so the inside
    // leads the outside, which is the way round a real roll goes.
    float r = length(uv);
    float2 q = ms_rot(uv, bank * (1.0 + 1.35 * turn * (0.26 - r))) / S;

    // THE SPLIT: the flock deciding. Every few seconds the mass is drawn apart
    // across a seam and comes back together. The two halves move in OPPOSITE
    // directions along the seam's normal, which is what a split is; a single
    // displacement would only be a lurch. The sign is taken with a smoothstep
    // rather than sign() because sign() has a discontinuity down the middle of
    // the seam and would draw a hairline crack through the flock. At envelope
    // zero this term is exactly zero and the material is the one Kris approved.
    float4 fSplit = ms_flourish(t, 3.0);
    float seam = fSplit.z * 6.2831853;
    float2 snorm = float2(cos(seam), sin(seam));
    float side = 2.0 * smoothstep(-0.11, 0.11, dot(uv, snorm)) - 1.0;
    // The seam displacement is kept in uv as well as applied to the fold domain,
    // because the figure arrived after this gesture did. Splitting only the
    // texture and leaving the ribbon whole would have been a flock whose
    // material tears while its silhouette sits still, which is a worse picture
    // than either. The band itself parts and comes back.
    float2 splitOff = snorm * (side * fSplit.x * 0.085);
    q += splitOff / S;

    // THE TRAVEL. A flock does not hover, and at the family's lifted tempo the
    // fold has to be seen CROSSING the mass rather than boiling in place -- a
    // faster boil is churn, and churn is the stormy failure. So the domain the
    // sheet is read in is advected. This costs a vector add and it is the whole
    // difference: the body envelope stays where it is, because it is measured in
    // uv and not here, so the MATERIAL streams through a mass that keeps its own
    // outline, which is exactly what a murmuration does. The heading leans with
    // the bank, so the flock travels the way it is turning.
    // RESPONDING: the flock stops casting about and COMMITS. The heading stops
    // leaning with the bank and holds one line, and the travel runs half again
    // as fast down it. A flock that has decided where it is going looks exactly
    // like this, and it is the same two numbers that make it look undecided.
    float head = mix(0.62 + bank * 0.85, 0.62, st.drive);
    q -= float2(cos(head), sin(head)) * (0.105 * t * (1.0 + 0.55 * st.drive));

    // The drag: one warp field along the tangent of the turn, because that is
    // the direction the flock's own motion carries its material.
    float2 tangent = float2(-uv.y, uv.x) / max(r, 1e-3);
    float warp = ms_fbm3(float3(q * 1.35 + float2(9.7, 3.1), t * 0.088), 2, 2.00, 0.50);
    float2 qw = q + tangent * (warp * (0.22 + 0.30 * flock) / S);

    // The sheet, and the level sets are taken PERIODICALLY. One zero level is a
    // single surface, and a single surface through a slice is one bright thread
    // -- the first cut of this shader drew exactly that, a wire in a haze, which
    // is a filament and not a flock. Several level sets at once give a stack of
    // soft bands that split, merge and vanish across the frame, which is a sheet
    // folded back over itself and is what a flock's density actually looks like.
    // exp(k(cos - 1)) is the smooth way to say "near a level set": periodic, no
    // discontinuity anywhere, and thickness is one number.
    float n = ms_fbm3(float3(qw * 2.85, t * 0.115), 3, 2.03, 0.52);

    // SUCCESS: THE FOLD BECOMES ONE CLEAN WAVE. The whole point of this species
    // is a sheet folding over itself in a way that never settles; for one breath
    // it settles, and the field the level sets are read from is carried onto a
    // single travelling sine. It is a mix, not a replacement, so the flock keeps
    // its own irregularity underneath and reads as the same bird mass arriving
    // at an order rather than as a different picture cut in.
    n = mix(n, 0.42 * sin(dot(uv, float2(0.87, 0.49)) * 8.4 - t * 1.15), st.complete * 0.88);
    // Two numbers do the work. `folds` is how many level sets the slice cuts:
    // two or three, because a flock is a sheet folded a few times and not a
    // pastry. `k` is how sharply the density peaks at each one, and it is kept
    // LOW -- a high k draws the level sets as bright filaments on black, which
    // is a vein and not a flock, and was what the second cut of this shader did.
    float folds = 1.8 + 1.5 * flock;
    float k = mix(0.30, 1.30, cohesion);
    float sheet = exp(k * (cos(6.2831853 * n * folds) - 1.0));

    // THE GRAIN. A second, much finer set of the SAME level sets, and it costs a
    // cosine rather than a noise tap because it reads the field that is already
    // in hand. This is where the mass gets its interior: a flock at any distance
    // has texture inside its body, and without this a 300 pt indicator is one
    // smooth lobe with a crease in it. It MULTIPLIES the sheet rather than
    // adding to it, so the grain exists only where there is material to have a
    // grain -- texture in empty sky would be the tell that this is a shader and
    // not a flock.
    float grain = exp(k * 1.40 * (cos(6.2831853 * n * folds * 2.60) - 1.0));
    sheet *= 0.72 + 0.42 * grain;

    // THE RIBBON, and it is the figure. A murmuration cuts a SHAPE against the
    // sky: a long band that curves, thick through its middle and tapering to
    // nothing at both ends, with the birds piled up along its leading edge. The
    // old body was a super-gaussian -- a circle -- so the species was a round
    // cloud of texture, and a round cloud of texture inside a round frame is not
    // an object, it is a fill. This is an object, and the fold field, which is
    // unchanged, now lives ON it.
    float2 ruv = ms_rot(uv + splitOff, 0.30 + 0.14 * sin(t * 0.15));

    // The centreline: one broad wave with a smaller one riding it, so the band
    // curves the way a flock's spine does and never reads as a drawn arc.
    float spine = 0.085 * sin(ruv.x * 5.2 + t * 0.62) + 0.042 * sin(ruv.x * 9.4 - t * 0.35);

    // Along the band: full through the middle, gone by either tip.
    float along = clamp(ruv.x / 0.40, -1.0, 1.0);
    float taper = pow(max(1.0 - along * along, 0.0), 0.62);

    float halfw = 0.048 + 0.105 * taper;
    float ribbon = (1.0 - smoothstep(halfw * 0.40, halfw, abs(ruv.y - spine))) * taper;

    // THE LEADING EDGE is where the birds bunch, and it is what sends this
    // species to cream: the value hierarchy wants the figure's key structure at
    // the top of the rail, and on a flock that structure is the front.
    float lead = smoothstep(-0.14, 0.36, ruv.x);

    // Normalised so the dense leading edge of the band actually arrives at the
    // top of the rail. The figure can be perfect and still fail the value law:
    // the first cut of this ribbon peaked around 0.7 and read as rust, because
    // its spine only reached one where the band's centre and a fold's crest
    // happened to coincide, which is a small part of a small part.
    float dens = ribbon * (0.34 + 0.66 * sheet) * (0.52 + 0.48 * flock)
               * (0.58 + 0.85 * lead) * 1.42;

    float skyN = ms_fbm3(float3(q * 0.75, t * 0.047), 2, 2.00, 0.50);
    float dusk = sky * (0.055 + 0.075 * (0.5 + skyN)) * (1.0 - 0.55 * dens);

    // The light of the arrival, and it is the species' own light scaled: dark
    // stays dark, so the surge travels through the fold and not over it.
    float eM = (dens + dusk) * (1.0 + 0.62 * st.complete + 0.16 * st.settled);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, eM, glow, 0.0, 1.0, 0.30);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 2. Loom

// LOOM. Threads finding a weave.
//
// The trap here is drawing thread. A thread drawn is a line, a line has an end,
// and an end inside a circle is a cut. So nothing in this species is drawn: the
// cloth is an INTERFERENCE. Two families of broad travelling waves cross at a
// near right angle, and what the eye reads as fabric is where they agree.
//
// THE OVER AND UNDER. Warp alone is a set of soft bands. Weft alone is the same
// set turned ninety degrees. Their SUM is a plaid and their PRODUCT is the
// weave: the product term is large only where a warp crest and a weft crest
// coincide, which is exactly where real cloth is thickest, so adding a little of
// it lifts the crossings above the bands and the surface stops being a grid and
// becomes a textile. `tension` is how much of that product is in the mix.
//
// WHY THE WEAVE IS NEVER SQUARE. The weft runs perpendicular to the warp plus a
// fixed four degrees. Exactly square is graph paper, and graph paper is the one
// thing cloth never looks like. Four degrees is below the angle anyone can name
// and above the angle at which the crossings line up into columns.
//
// THE WANDER. Each family's phase is displaced by a one-dimensional fBm read
// ALONG its own threads, so a thread bends over its length the way a thread
// under real tension does, and never by so much that two of them cross. Slack
// threads wander; taut ones do not, which is the whole of `tension`'s second
// job.
//
// RESOLVING AND RELAXING. The roster asks for cloth that forms and eases off
// again, so there is a slow cycle here, at about fifty five seconds. It moves
// STRUCTURE, not brightness: at the taut end the wander collapses and the
// crossings sharpen into fabric; at the slack end the threads wander apart and
// the surface goes back to two independent sets of waves. The luminance mean
// barely moves across the cycle, which is the difference between a loom and a
// blinking light.
//
// THE SHEEN is a directional highlight off the weave's own slope. The phases are
// closed-form sines, so cos(phase) IS the slope: no derivative machinery, no
// finite differences, one dot product against a fixed light direction. It is
// what makes cloth look like cloth and it is nearly free.
[[ stitchable ]] half4 ms_loom(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float threads = clamp(c0, 0.0, 1.0);   // the pitch of the weave
    float tension = clamp(c1, 0.0, 1.0);   // taut cloth or slack thread
    float sheen   = clamp(c2, 0.0, 1.0);   // the highlight off the weave's face
    float angleK  = clamp(c3, 0.0, 1.0);   // which way the bolt is hung

    float2 q = uv / S;

    // The two axes. The weft is perpendicular plus four degrees; see above.
    float a = (angleK - 0.5) * 1.30 + 0.32;
    float2 d1 = float2(cos(a), sin(a));
    float2 d2 = float2(cos(a + 1.6406), sin(a + 1.6406));

    // The pitch. 18 to 44 puts between three and seven cycles across the
    // indicator, which is the band where a weave reads as cloth at 20 pt and
    // still has structure worth looking at across 300 pt. Higher is a comb.
    float K = mix(17.0, 42.0, threads);
    float aa = ms_aa(K / S, size, pixelScale);

    MSState st = ms_state(stateIndex, stateTau);

    // THE LOOM'S BEAT: taut, then eased, then taut. About thirty five seconds,
    // which is long enough that the cycle is felt and never counted.
    float beat = 0.5 + 0.5 * sin(t * 0.1828);
    // SUCCESS: THE CLOTH RESOLVES. Tension goes to its maximum and the threads
    // stop wandering, so for one breath the weave is crisp and square and
    // finished -- which is the one thing this species spends the rest of its
    // life approaching and letting go of.
    float taut = clamp(max(tension * (0.42 + 0.58 * beat), st.complete), 0.0, 1.0);
    float wander = mix(1.15, 0.20, taut) * (1.0 - 0.85 * st.complete);

    // THE DRAPE, and it is the first thing that happens because everything else
    // is read against it. One slow two-dimensional warp displaces the domain
    // BOTH families are read in, so the whole cloth folds together the way a
    // bolt lying on a table does. Warping the families separately would have
    // been cheaper and wrong: two independently wandering thread sets are not a
    // fold, they are a mistake in the weaving.
    float3 dq = float3(q * 0.85, t * 0.042);
    float drapeA = ms_fbm3(dq, 2, 2.00, 0.50);
    float drapeB = ms_fbm3(dq + 21.7, 2, 2.00, 0.50);
    float2 qd = q + float2(drapeA, drapeB) * 0.30;

    // Each family wanders along its OWN threads, so threads bend over their
    // length instead of the whole sheet sliding.
    float w1 = ms_fbm1(dot(qd, d2) * 1.9 + t * 0.083, 3, 4.0);
    float w2 = ms_fbm1(dot(qd, d1) * 1.9 - t * 0.062, 3, 61.0);

    // THE SPACING BREATHES, and this is what stops the weave reading as a
    // printed grid. A cloth beaten by hand is not evenly spaced: the reed packs
    // some picks tighter than others across the width of the bolt. The local
    // wavenumber is K plus the GRADIENT of whatever else is in the phase, so a
    // very slow field with a large amplitude is not a wobble -- it is a slow
    // change of spacing, which is exactly the irregularity a hand loom leaves.
    // Nine radians over the frame moves the pitch by about a third at its
    // extremes, which is visible as cloth and never as an error.
    float br1 = ms_fbm1(dot(qd, d2) * 0.50 - t * 0.035, 2, 91.0);
    float br2 = ms_fbm1(dot(qd, d1) * 0.50 + t * 0.029, 2, 137.0);

    // Time enters as a slow crawl of the phases, which is the cloth being fed
    // through the loom, not a brightness on a timer.
    // The wander is worth several radians, not a fraction of one: at K around
    // thirty the phase runs to thirty radians across the frame, so a displacement
    // under a radian is invisible and the weave comes out as machine-ruled.
    // THE PULL: one thread drawn taut through the cloth, then let go. A narrow
    // gaussian in the across-coordinate picks a single thread's worth of the
    // weave and runs its phase forward, which slides that one thread through the
    // cloth while its neighbours hold. It also stops WANDERING for the duration,
    // because that is what taut means: a thread under tension is a thread that
    // has stopped meandering. Both halves ride the same envelope home.
    float4 fPull = ms_flourish(t, 12.0);
    float pz = (dot(qd, d2) - (fPull.z - 0.5) * 0.70) / 0.075;
    float pull = fPull.x * exp(-pz * pz);

    // RESPONDING: the bolt runs. The crawl that feeds cloth through the loom
    // more than doubles and both families run the same way, so the weave has a
    // direction instead of a shimmer.
    float feed = 1.0 + 1.30 * st.drive;

    float ph1 = dot(qd, d1) * K + w1 * wander * 5.5 * (1.0 - 0.65 * pull)
              + br1 * 7.0 - t * 0.68 * feed + pull * 5.20;
    float ph2 = dot(qd, d2) * K + w2 * wander * 5.5 + br2 * 7.0 + t * 0.54 * feed;

    float warp = mix(0.5, 0.5 + 0.5 * sin(ph1), aa);
    float weft = mix(0.5, 0.5 + 0.5 * sin(ph2), aa);

    // THE FACE. Cloth has one, and the two families are NOT equal partners: the
    // warp is what the eye reads and the weft is what it feels. Two earlier cuts
    // gave them equal weight and got, in order, a lattice of round blobs (from
    // their SUM, which is bright where both crest and dark where both trough)
    // and then a waffle iron (from their union). Weighting the warp at twice the
    // weft, over a substantial body of cloth, gives a surface with a direction,
    // which is what every woven thing has.
    //
    // The last term is the over and under: at a crossing one thread passes
    // beneath the other and takes a little light down with it, so a crossing
    // DIPS instead of piling up. The sign of that is most of the difference
    // between cloth and a grid.
    float cloth = 0.32 + 0.50 * warp + 0.26 * weft - taut * 0.26 * warp * weft;

    // The bolt is not uniform: it has weight in some places and is nearly sheer
    // in others. This is the drape field read a second time rather than a third
    // noise tap, which is also the truer statement -- where the cloth folds is
    // where it doubles, and where it doubles is where it is heaviest.
    float bolt = 0.62 + 0.55 * (0.5 + drapeA);

    // THE SHEEN. cos(phase) is the slope; the fixed vector is the light.
    float slope = 0.78 * cos(ph1) * aa - 0.46 * cos(ph2) * aa;
    float spec = pow(clamp(0.5 + 0.5 * slope, 0.0, 1.0), 5.0);

    // Handed over uncapped: the crossings and the sheen together pass 1 in the
    // brightest places, and ms_lit's knee is where that is meant to be resolved.
    // THE PATCH, and it is the figure. Cloth on a loom has a selvedge: it is a
    // piece of something, not a wallpaper. The boundary is an ellipse perturbed
    // by the drape field already in hand, so its edge is irregular and soft and
    // costs no extra tap, and the weave lives INSIDE it with ink all round.
    // Allover weave to the rim was the fill this pass exists to kill.
    float2 pc = uv - 0.022 * float2(sin(t * 0.11), cos(t * 0.09));
    float rr = length(pc * float2(1.0, 1.22)) + 0.085 * drapeB;
    float patch = 1.0 - smoothstep(0.185, 0.315, rr);

    // The taut crossings and the sheen are the key structure and take the top of
    // the rail; the body of the cloth stays amber underneath them.
    float e = (cloth * bolt * (0.56 + 0.26 * taut) + sheen * 1.05 * spec * cloth)
            * patch * 1.55
            * (1.0 + 0.58 * st.complete + 0.15 * st.settled);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 1.0, 0.34);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.58), position, pixelScale);
}

// MARK: - 3. Cipher

// CIPHER. Meaning surfacing.
//
// The idea is older than the shader: the structure was always there, and what
// changes is not the structure but whether anything is looking at it. So this
// species has two parts and they are strictly separated. There is a LATENT
// field, four octaves, present at every pixel at every instant, drifting slowly
// and owing nothing to the viewer. And there is an ATTENTION: one broad soft
// region wandering the disc. The attention does not add light. It lowers a
// THRESHOLD, and the latent field's own level sets rise through it.
//
// That is why the shapes that appear are worth looking at. They are not a
// spotlight's disc: they are the islands of a real field, ameboid, connected,
// arriving and closing as the threshold moves, and they are different every time
// because the field underneath is. A brightness mask would have given the same
// blob wherever the attention went. This gives the picture the FIELD keeps.
//
// STRUCTURE is a mix between the smooth field and its own crease transform,
// 1 - |n|. The crease version puts filigree in the revealed islands -- fine
// connected ridges, still continuous, still soft, never a mark. At zero the
// islands are simple lobes; at one they have a filamented interior. Both ends
// are legible at 20 pt because both are the same broad islands.
//
// THE WANDER is two sines whose frequencies do not divide, at 0.24 of the frame,
// so the attention crosses the disc on a path that never repeats and never
// reaches the rim. DWELL slows it and widens it: a slow attention lingers, and
// lingering is what dwelling looks like from outside.
//
// SCATTER is the residue: how much of the latent field shows where nothing is
// looking. It is small by default, and it is not decoration -- it is the reason
// the dark parts of this indicator are a dark FIELD and not a dark hole.
[[ stitchable ]] half4 ms_cipher(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float reveal    = clamp(c0, 0.0, 1.0);   // how far the threshold drops
    float structure = clamp(c1, 0.0, 1.0);   // lobes, or lobes with filigree
    float dwell     = clamp(c2, 0.0, 1.0);   // how slowly attention moves
    float scatter   = clamp(c3, 0.0, 1.0);   // the residue outside attention

    // THE LATENT FIELD. Four octaves, the pack's ceiling, because this is the
    // one species whose whole subject is that there is something detailed under
    // the dark. Its own drift is very slow: the meaning is not going anywhere.
    float2 q = uv / S;
    float lat = ms_fbm3(float3(q * 2.60, t * 0.072), 4, 2.03, 0.52);

    float lobes  = clamp(0.5 + 1.15 * lat, 0.0, 1.0);
    float crease = 1.0 - clamp(abs(lat) * 2.30, 0.0, 1.0);
    float psi = mix(lobes, crease, structure);

    // THE ATTENTION. Slower and wider as dwell rises.
    MSState st = ms_state(stateIndex, stateTau);

    // THE REVEAL HAS TO PASS, and the first cut's did not. Attention orbited
    // inside a sixth of the frame at a rate that took thirteen seconds to get
    // anywhere, so what a viewer saw in three seconds was a patch of light
    // breathing in place -- "it kind of shifts around", which is the exact
    // failure this pass exists to kill. The verb is PASSES: the amplitude is
    // now most of the disc and the traverse is quick enough to read, so a
    // legible attention crosses the field and takes the meaning with it.
    // RESPONDING makes that traverse decisive: the wandering Lissajous is
    // straightened toward one steady sweep across the frame.
    float rate = mix(1.55, 0.55, dwell) * (1.0 + 0.70 * st.drive);
    float2 orbit = 0.30 * float2(sin(t * rate * 0.83), sin(t * rate * 0.61 + 2.1));
    float2 sweep = float2(sin(t * rate * 0.83), 0.34 * sin(t * rate * 0.29));
    float2 ac = mix(orbit, 0.30 * sweep, st.drive);

    // THE SECOND LOOK: attention darts off its path and comes back. It moves the
    // ATTENTION, not the light -- the threshold goes with it, so what surfaces
    // during the dart is whatever the latent field happens to hold over there,
    // which is different every time because the field is. A brightness flick
    // would have shown the same shape brighter; this shows a different thought.
    float4 fLook = ms_flourish(t, 21.0);
    float lookA = fLook.z * 6.2831853;
    ac += float2(cos(lookA), sin(lookA)) * (fLook.x * 0.135);
    // Tighter than it was, so the thing crossing reads as an attention with an
    // edge rather than as a general warming of the frame.
    // THE ARC, and it is the figure. Attention was a round soft patch, which is
    // a blob, nameable as nothing. It is now a BAND OF CONSTANT RADIUS about a
    // centre that sits outside the frame, so what crosses the disc is an arc: a
    // curved sweep with two ends and a direction, legible as a shape in itself.
    // The centre swings around the outside, which is what makes the arc pass.
    float arcAng = atan2(ac.y, ac.x);
    float2 actr = 1.08 * float2(cos(arcAng), sin(arcAng));
    float arcW = mix(0.090, 0.135, dwell);
    float ad = (length(uv - actr) - 0.94) / arcW;
    float att = exp(-ad * ad);

    // The threshold. High everywhere by default -- almost nothing crosses it --
    // and pulled down where attention is. The 0.30 band above it is the softness
    // of the coastline: narrower and the islands get a hard edge, which organic
    // forms are never allowed.
    // SUCCESS: THE WHOLE FIELD SURFACES. The threshold drops everywhere at once
    // for one breath, so the latent structure that is normally lit only where
    // something is looking is, briefly, entirely legible: the species' own idea
    // of having understood the thing.
    float thr = mix(0.72, 0.30, clamp(reveal * att + scatter * 0.18
                                      + st.complete * 0.95, 0.0, 1.0));
    // The 0.34 band above the threshold is the softness of the coastline, and it
    // is wide on purpose twice over: narrower and the islands get an edge, which
    // organic forms may never have, and narrower also means the interior
    // saturates flat, which walked the rail into its pale specular and turned an
    // amber island white.
    float e = smoothstep(thr, thr + 0.34, psi);

    // THE RESIDUE, and it is not decoration. Without it the parts of the disc
    // that attention has not reached are flat ink, and a flat-ink indicator
    // reads as switched off rather than as thinking about something else. The
    // floor is present even at scatter zero, because the latent field is the
    // premise of the species: it is always there whether or not it is lit.
    e = max(e, (0.10 + 0.30 * scatter) * smoothstep(0.38, 0.92, psi));

    // The arc carries light of its own and not only a threshold. It is the
    // figure, and a figure the eye has to hunt for is not doing its job: its
    // core is the key structure and goes cream while the mass it crosses stays
    // amber underneath.
    e = max(e, att * (0.52 + 0.62 * reveal) * (0.55 + 0.45 * psi));

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e * (1.0 + 0.42 * st.complete + 0.14 * st.settled),
                          glow, 0.0, 1.0, 0.30);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 4. Tuning  (arc)

// TUNING. Static finding the station.
//
// THE FIRST CUT OF THIS SHADER WAS MUD, and the reason is worth writing down
// because it is a general trap. It built the picture as ONE term: a broadband
// field inside an envelope that narrowed. But a noise field inside an envelope
// is still a noise field -- its value wanders over the whole range everywhere,
// including inside the band, so the band had no edge, no continuity along its
// length, and no contrast against a surround that never fully gave up its
// energy. The result was an out-of-focus rust smudge with faint banding in it,
// which is what "static and a station added together" looks like when they are
// the same term.
//
// So the station and the noise are now TWO SEPARATE TERMS, and the arc is the
// handover between them.
//
//   THE STATION  a soft luminous ridge along a gently wandering line. Its
//                half-width is the arc: 0.46 at birth, which is wider than the
//                whole disc and therefore invisible AS a line, down to about
//                0.05 at rest, which is unmistakably one. Its brightness along
//                its length is modulated by the field, so it is alive and
//                textured, but the modulation never takes it below 0.58 -- a
//                station that breaks into pieces is not a station.
//   THE SPREAD   broadband energy still distributed over the whole frame. The
//                arc drains it. This is the static, and at birth it is the
//                entire picture.
//   THE FLOOR    hiss that never leaves, because a receiver locked onto a
//                station still hisses underneath it and an indicator that
//                reaches silence has stopped thinking.
//
// The spectrum still narrows underneath all three: four octaves under a gaussian
// passband, wide at birth and one octave wide at rest, with the domain squeezed
// along the station's axis so the surviving octave becomes a striation running
// ALONG the line rather than a texture across it.
//
// THE ARC IS A LAW, NOT AN ANIMATION. ms_settle_law states the scramble SPEED
// and hands back its exact integral, so the domain's position at any t is the
// position it would have reached, and the shader is deterministic under a
// screenshot rig or a scrubbed slider. `epoch` restarts it.
//
// WHAT `lock` NOW MEANS, and this changed. It used to cap the arc itself, which
// meant that at the default of 0.5 the station never actually arrived -- half a
// lock is a smudge, and "coherent is rest" was not being honoured at the setting
// most people would see. The arc now always completes; `lock` sets how NARROW
// and how PURE the settled station is: a hair-fine line over almost nothing at
// 1, a broader warm band with more of the broadband still around it at 0. Both
// ends are a station. Neither end is mud.
//
// SETTLED IS NOT STOPPED. The law's floor keeps the field boiling at a twentieth
// of its birth rate forever; the line itself is displaced by a one-dimensional
// fBm that never stops wandering, so a held station breathes like a needle
// holding a signal; and the ends of the line taper away well before the rim, so
// what the circle contains is a soft line of light and never a rule drawn
// across it.
[[ stitchable ]] half4 ms_tuning(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float band  = clamp(c0, 0.0, 1.0);   // which scale the station sits on
    float lock  = clamp(c1, 0.0, 1.0);   // how narrow and how pure, once settled
    float hiss  = clamp(c2, 0.0, 1.0);   // the floor that never leaves
    float drift = clamp(c3, 0.0, 1.0);   // the settled needle's wander

    // THE ARC. Six seconds is the tempo of an answer arriving: long enough that
    // the search is legible, short enough that a chat UI is not made to wait.
    // The house rate dial stays OUT of it, the way the pour keeps exhaleTime in
    // real seconds, so a slower field still settles when it says it will.
    MSState st = ms_state(stateIndex, stateTau);

    float tau = max(time - epoch, 0.0);
    float3 law = ms_settle_law(tau, 6.0);
    // SUCCESS: THE STATION LOCKS DEAD CENTRE. The arc is carried to its end,
    // the needle's wander is taken out and the line is pulled onto the centre
    // line -- for one breath the receiver is perfectly tuned, which is the thing
    // this species is always nearly doing and never quite finishing.
    float arc = clamp(max(1.0 - law.z, st.complete), 0.0, 1.0);
    // The scramble runs at nearly twice its first tempo. This multiplies the
    // law's DISTANCE, not its time constant, so the arc still completes in the
    // six real seconds it promises -- what got faster is how hard the static
    // boils while the search is on, and how live the held station is after.
    // RESPONDING: the dial is being worked. The scramble runs harder and the
    // needle sweeps along the station instead of breathing in place.
    float scroll = law.y * 1.90 * max(speed, 0.0) * (1.0 + 0.85 * st.drive);

    // Six degrees off level. A station is a line, but a line at exactly zero
    // degrees inside a circle reads as a rule someone drew in the UI.
    // The station's GEOMETRY is measured in uv and not in the form-scale domain:
    // a line is a line at any zoom, and only its texture and its wavelength
    // belong to the form scale.
    float2 ruv = ms_rot(uv, 0.105);
    float2 pq = ruv / S;

    // THE NEEDLE. The line is displaced along its length by a one-dimensional
    // fBm that never stops moving, so a locked station still breathes. `drift`
    // sets how far. This is also why the line can never read as a UI rule: a
    // rule is straight and this is not, at any setting.
    float needle = ms_fbm1(ruv.x * 3.10 + t * (0.170 + 0.30 * st.drive), 3, 17.0)
                 * (0.022 + 0.062 * drift) * (1.0 - 0.95 * st.complete);
    float across = ruv.y - needle;

    // THE SLIP: the station wanders off frequency and re-locks. The whole line
    // slides across the dial and loses its edge while it is off, then settles
    // back onto the same station -- the dial is never actually retuned, which is
    // why this is play and not a second arc. Both terms are geometry: where the
    // line is and how wide it is. Nothing about the light changes.
    float4 fSlip = ms_flourish(t, 30.0);
    float slip = fSlip.x;
    // The slip is suppressed on success rather than the coordinate being
    // scaled. Scaling `across` was the first cut and it is exactly backwards:
    // multiplying the across-coordinate down brings the whole frame INSIDE the
    // gaussian, so the band swells into a filled blob instead of narrowing onto
    // a line. Dead centre means the offsets go away -- the needle's wander and
    // the slip -- while the width narrows on its own through sigma.
    across += slip * (fSlip.z * 2.0 - 1.0) * 0.058 * (1.0 - st.complete);

    // THE HALF-WIDTH, which is the whole arc in one number. At birth it is wider
    // than the disc, so the "band" is a flat wash and the picture is whatever
    // the noise is doing -- static. At rest it is a line. `lock` chooses how
    // fine a line.
    float sigma = mix(0.46, mix(0.115, 0.042, lock), arc)
                * (1.0 + 0.60 * slip) * (1.0 - 0.45 * st.complete);
    float prof = exp(-(across * across) / (sigma * sigma));

    // The ends taper well before the rim. Without this the settled state is a
    // chord across a circle, which is a rule someone drew, and the brief's one
    // absolute for this species is that it must never become that.
    float along = 1.0 - smoothstep(0.26, 0.46, abs(ruv.x));
    prof *= along;

    // THE PASSBAND. Wide at birth, one octave wide when settled.
    float centre = 0.20 + 1.70 * band;
    float width = mix(2.30, 0.52, arc);
    // The squeeze along the station's axis: at birth the domain is isotropic and
    // the field has no direction; settled, x barely moves it and the surviving
    // octave is a striation running ALONG the line instead of across it.
    float xs = mix(1.0, 0.08, arc);
    float f0 = mix(2.2, 5.2, band);

    // The passband, octave by octave, each one gated on whether this frame can
    // actually resolve it. Without the gate a 20 pt indicator puts the top
    // octave at better than a cycle a pixel and the static comes back as
    // sparkle, which is the one thing this family may never draw.
    float acc = 0.0, wsum = 0.0;
    for (int i = 0; i < 4; i++) {
        float oct = exp2(float(i));
        float d = (float(i) - centre) / width;
        float w = exp(-d * d) * ms_aa(6.2831853 * f0 * oct / S, size, pixelScale);
        acc += w * ms_noise3(float3(pq.x * xs * f0 * oct,
                                    (across / S) * f0 * oct,
                                    scroll * (0.42 + 0.30 * float(i)) + float(i) * 19.0));
        wsum += w;
    }
    float v = acc / max(wsum, 1e-4);
    float v01 = clamp(0.5 + 1.30 * v, 0.0, 1.0);

    // THE THREE TERMS.
    //
    // The station's texture floors at 0.58 rather than reaching zero: the field
    // modulates the line's brightness along its length so it is alive, but a
    // line that the noise is allowed to cut into pieces stops being one thing,
    // and one thing is what a 76 pt indicator has room to say.
    float station = prof * (0.58 + 0.42 * v01);
    // What is still spread over the whole frame. At birth this is the picture.
    float spread = mix(1.0, mix(0.30, 0.12, lock), arc) * 0.42 * v01;
    // The floor. Gated on the same resolution test so it stays a noise FLOOR at
    // every size: audible under the station, never a grain of sand on the glass.
    float hz = ms_noise3(float3(pq * 8.5, scroll * 1.7 + 41.0));
    float floorHiss = hiss * mix(0.42, 0.27, arc) * (0.12 + 0.88 * (0.5 + hz))
                    * ms_aa(6.2831853 * 8.5 / S, size, pixelScale);

    // The station is also allowed to get brighter as it arrives, because a
    // receiver that has found a signal is putting the energy it was spreading
    // over the whole band into one place. Between the narrowing and this, the
    // settled line runs about ten times the luminance of its surround, which is
    // what lifts it out of the mud the first cut lived in.
    float e = (station * mix(0.42, 0.98, arc) + spread + floorHiss)
            * (1.0 + 0.40 * st.complete + 0.15 * st.settled);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 1.0, 0.34);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.58), position, pixelScale);
}

// MARK: - 5. Current

// CURRENT. Signal moving through a medium.
//
// Every diagram of a network is wrong for this: wires have ends, nodes are dots,
// and both are banned. What is true instead is that a medium CONDUCTS unevenly,
// and an impulse moving through it lights the parts that conduct. So there is no
// network here. There is a conductance field and a travelling phase, and the
// picture is their product.
//
// THE CONDUCTANCE. A three octave field, either read straight (broad soft
// regions, `branch` at zero) or through its crease transform 1 - |n| (a
// branching filamented system, `branch` at one). The crease version is what
// gives the sense of pathways, and it is still a field: its channels are wide,
// soft-sided and connected, and they never terminate in anything. `pathways`
// moves the frequency, which is the honest way to ask for more of them.
//
// THE IMPULSE. A phase built from a broad direction plus a two octave bend, so
// wavefronts follow the medium's own shape instead of marching across it as a
// front. What travels is a von Mises bump on that phase: exp(k(cos - 1)) is
// periodic, has no discontinuity anywhere, and its width is one number. A
// fract() sawtooth was the obvious alternative and it has a step in it, and a
// step is a hard edge, and organic forms do not get hard edges.
//
// THE WAKE. The phase is skewed by adding 0.55 sin(phase) before the bump is
// taken, which steepens the leading edge and stretches the trailing one without
// breaking periodicity or continuity. That asymmetry is the entire difference
// between an impulse travelling and a stripe sliding.
//
// AFTERGLOW is the refined name for the roster's third knob. It was written down
// as "glow", but the shader already has a glow dial and a second one would just
// be a brightness. What it means here is how far the impulse's light escapes the
// channel into the surrounding medium and how long a tail it drags: at zero the
// signal is confined and quick, at one it bleeds into the material around it and
// takes its time leaving. That is a property of the medium, which is what this
// species is about.
[[ stitchable ]] half4 ms_current(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float pathways  = clamp(c0, 0.0, 1.0);   // how finely the medium is divided
    float pulseRate = clamp(c1, 0.0, 1.0);   // how often an impulse passes
    float afterglow = clamp(c2, 0.0, 1.0);   // bleed into the medium, and wake
    float branch    = clamp(c3, 0.0, 1.0);   // regions, or a branching system

    MSState st = ms_state(stateIndex, stateTau);

    float2 q = uv / S;

    // THE MEDIUM.
    // THE DELTA, and it is the figure. Ridged noise gave a network in the sense
    // that a mud flat is a network: everywhere, equally, with no trunk and no
    // direction, and at 20 pt it was mush with a bright streak in it. A delta
    // has ONE ARTERY and a few branches leaving it, which is a shape a person
    // can name and trace with a finger. So the channels are DRAWN, not sampled:
    // one trunk and three branches, each a bending line with two ends, unioned.
    // The medium's noise is still here and still does the same job -- it now
    // modulates the artery's density instead of being the whole picture.
    // The branch roots are placed ON the trunk by construction rather than by
    // eye. A vein's frame is a rotation, so a point at trunk-local (a, c(a)) is
    // at world origin + rot((a, c(a)), -ang) -- three lines of arithmetic that
    // guarantee each branch leaves the artery from a point that is actually on
    // it. Guessing the offsets was the first cut and it drew four separate
    // wedges, which is not a delta, it is debris.
    const float A0 = -0.58, F0 = 6.2, B0 = 0.052;
    float ph0 = t * 0.31;
    // ms_vein's line runs in direction (cos ang, -sin ang), so a negative angle
    // heads UP and to the right. The root therefore has to sit low and left for
    // the artery to cross the frame; the first cut put it high and left, so the
    // trunk left the disc almost immediately and all that survived was a stub.
    float2 root = float2(-0.36, -0.26);
    float bw = 0.050 + 0.028 * pathways;
    float trunk = ms_vein(uv - root, A0, B0, F0, ph0, bw * 1.30, 0.92);

    float a1 = 0.26, a2 = 0.44, a3 = 0.62;
    float2 r1 = root + ms_rot(float2(a1, B0 * sin(a1 * F0 + ph0)), -A0);
    float2 r2 = root + ms_rot(float2(a2, B0 * sin(a2 * F0 + ph0)), -A0);
    float2 r3 = root + ms_rot(float2(a3, B0 * sin(a3 * F0 + ph0)), -A0);

    float br1 = ms_vein(uv - r1, A0 - 0.78, 0.030, 10.0, ph0 + 2.1, bw * 0.72, 0.34);
    float br2 = ms_vein(uv - r2, A0 + 0.66, 0.026, 11.5, ph0 + 4.3, bw * 0.64, 0.30);
    float br3 = ms_vein(uv - r3, A0 - 0.52, 0.024, 12.5, ph0 + 1.2, bw * 0.56, 0.26);
    // A max union: each branch keeps its own silhouette instead of brightness
    // piling up wherever two of them happen to cross.
    float tree = max(max(trunk, br1 * (0.72 + 0.28 * branch)),
                     max(br2 * (0.62 + 0.38 * branch), br3 * (0.55 + 0.45 * branch)));

    float fq = mix(1.70, 3.30, pathways);
    float3 pm = float3(q * fq, t * 0.068);
    float n = ms_fbm3(pm, 3, 2.03, 0.55);
    float chan = tree * (0.62 + 0.52 * clamp(0.5 + 1.30 * n, 0.0, 1.0));

    // The same medium at half the frequency: what the light looks like once it
    // has scattered out of a channel and into the material either side. Not a
    // blur of `chan`, and not pretending to be one -- it is the broad component
    // of the same field, which is what a scattered version of it actually is.
    float halo = clamp(0.5 + 1.15 * ms_fbm3(pm * 0.55 + 13.0, 2, 2.00, 0.50), 0.0, 1.0);

    // THE PHASE. The bend dominates the straight term on purpose: wavefronts
    // that follow the medium read as transport through it, and a straight front
    // reads as a wipe.
    // RESPONDING: the impulses acquire a direction. The bend that makes
    // wavefronts follow the medium is halved and the straight term is doubled,
    // so instead of light wandering the network the whole front runs ONE WAY --
    // which is what a medium carrying an answer looks like.
    // SUCCESS: the network fires as one. The bend goes almost entirely, so
    // every pathway crests together for a breath: the pattern completing, in a
    // species whose pattern is simultaneity.
    float bend = ms_fbm3(float3(q * 1.15, t * 0.045), 2, 2.00, 0.50);
    float straight = 4.20 * (1.0 + 1.05 * st.drive);
    float bendAmt = 9.00 * (1.0 - 0.45 * st.drive) * (1.0 - 0.88 * st.complete);
    float phase = dot(q, float2(0.62, 0.38)) * straight + bend * bendAmt;

    float rate = mix(0.57, 2.35, pulseRate) * (1.0 + 0.80 * st.drive);
    // THE SURGE: one stretch of the medium briefly carries the signal faster,
    // so an impulse runs ahead of the rest of the front and then falls back into
    // step. It is a phase advance inside a soft region -- a change in WHERE the
    // wave is, which is the only honest way to say "faster" in a field whose
    // motion lives in its phase.
    float4 fSurge = ms_flourish(t, 44.0);
    float surgeA = fSurge.z * 6.2831853;
    float2 sc = 0.26 * float2(cos(surgeA), sin(surgeA));
    float sz = length(uv - sc) / 0.30;

    float th = phase - t * rate * 2.0 - fSurge.x * exp(-sz * sz) * 3.40;
    float skew = th + 0.55 * sin(th);                 // steep front, long wake
    float k = mix(3.40, 1.50, afterglow);             // and how long
    float pulse = exp(k * (cos(skew) - 1.0));

    // Three terms, and the first one matters more than it looks. The medium is
    // lit BY ITS OWN CONDUCTANCE even where no impulse is passing, so the
    // pathways are faintly legible at all times and an impulse arrives INTO
    // something rather than onto nothing. A flat floor instead of chan * chan
    // gave a uniform warm wash with a blob moving over it, which is a lamp
    // behind a card and not a signal in a medium.
    // The spine of the artery under an impulse is the key structure and reaches
    // cream; the branches and the resting delta stay amber below it.
    float e = (chan * (0.26 + 0.34 * chan)
            + chan * pulse * 1.15
            + afterglow * 0.30 * halo * pulse * chan) * 1.18
            * (1.0 + 0.70 * st.complete + 0.16 * st.settled);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 1.0, 0.34);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 6. Veil

// VEIL. Layers of translucency sliding.
//
// THE FIRST CUT WAS MUD, for a reason that is the exact mirror of the tuning's.
// It stacked three noise fields that each covered the WHOLE disc, and three
// overlapping full-coverage fields average into one mottled field: there was
// nothing to be in front of anything, because nothing had an edge. Depth needs a
// silhouette. If every sheet is everywhere, the eye has no boundary to read and
// the parallax it is being shown has nothing to attach to.
//
// So the sheets now have SHAPE. Each is a broad low-frequency field pushed
// through a soft threshold, which gives it one or two big lobes across the frame
// with a soft but definite boundary and genuine gaps between them. Where two
// scrims overlap the picture is darker; where all three do, darker again; where
// a gap opens in all of them, the thing behind shows through. Those crossings
// are the layer boundaries, and they are legible in a single still because they
// are real occlusion and not a blend mode.
//
// WHAT IS BEHIND is now a fourth thing and the brightest thing: a finer, higher
// contrast field at the very back with no scrim of its own. It is what the veils
// are veiling. It is never fully revealed, because even a pixel with all three
// scrims open still only sees it through the transmittance the gaps allow and
// through its own threshold, and it is never hidden either, which is what
// "almost legible" means. `legibility` works both ends of that: it sharpens what
// is behind and thins the scrims in front of it.
//
// THE COMPOSITE is the one physical statement in the species: each scrim adds
// its own light times what is left of the light path, then takes its bite out of
// the path with T *= (1 - alpha), and the thing behind gets whatever T survives.
// That is why the back is dimmed by exactly the scrims in front of it, per
// pixel, which is the thing a stack of blend modes cannot fake.
//
// THE PARALLAX is inferred from two cues and nothing is scaled or blurred to get
// it: nearer scrims slide faster and are coarser on screen, further ones slide
// slower and are finer, because more of a distant thing fits in the same angle.
//
// `layers` is a separation, not a count. The loop is fixed at three, because a
// variable loop is not allowed and because three is what reads: at zero the
// scrims converge onto nearly the same scale and rate and the picture is one
// veil over the thing behind, and at one they pull into three plain depths.
[[ stitchable ]] half4 ms_veil(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float layers     = clamp(c0, 0.0, 1.0);   // how far apart the depths sit
    float parallax   = clamp(c1, 0.0, 1.0);   // how differently they slide
    float legibility = clamp(c2, 0.0, 1.0);   // how near the back one comes
    float drift      = clamp(c3, 0.0, 1.0);   // the sliding itself

    MSState st = ms_state(stateIndex, stateTau);

    float2 q = uv / S;
    float sep = 0.30 + 0.70 * layers;
    // THE LAYERS HAVE TO SLIDE AGAINST EACH OTHER, and at the old rate they did
    // not read as sliding at all -- a scrim crossing a fifth of the frame in ten
    // seconds is a scrim standing still. The base rate is up by half again and
    // RESPONDING doubles it, which is what makes the verb legible in three
    // seconds: SLIDES.
    float base = (0.210 + 0.420 * drift) * (1.0 + 1.00 * st.drive);

    float4 fPart = ms_flourish(t, 57.0);

    float acc = 0.0;     // light gathered, already attenuated by what is in front
    float T = 1.0;       // what is left of the light path
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float far = fi * 0.5;                       // 0, 0.5, 1 front to back

        // Nearer scrims are coarser on screen and slide faster; further ones are
        // finer and slower, because more of a distant thing fits in the same
        // angle. Each has its own heading too, so this is parallax and not one
        // translation of three copies.
        float f = 1.12 * (1.0 + 1.15 * fi * sep);
        float rate = base / (1.0 + 2.10 * fi * parallax);
        // The headings are pulled far apart. Three sheets drifting within half
        // a radian of each other read as one sheet with texture; a radian and a
        // half between them and the eye sees three planes crossing, which is the
        // only cue that says depth without anything being drawn.
        float head = 0.55 - 1.55 * fi;
        // THE PARTING: the scrims draw apart and close again. The near sheet
        // and the far sheet are pushed OPPOSITE ways, so the gaps between them
        // widen and more of the thing behind arrives -- and it arrives because
        // the geometry opened, not because anything was turned up. That is the
        // whole species restated as a gesture: depth is what you see through.
        float2 slide = float2(cos(head), sin(head))
                     * (rate * t + fPart.x * (1.0 - fi) * 0.070);

        float n = ms_fbm3(float3(q * f + slide, t * 0.030 + fi * 7.3), 2, 2.03, 0.50);
        float d = clamp(0.5 + 1.35 * n, 0.0, 1.0);

        // THE PANE, and it is the figure. Three soft-silhouetted noise fields
        // read as one cloud however differently they slide, which is what the
        // veil was and why "layers" never landed. A layer needs an EDGE. Each
        // scrim is now a rounded rectangle, offset and turned a little from the
        // one behind it and sliding on its own heading: a stacked-panes gestalt
        // a viewer parses at a glance, with the noise living on the glass as its
        // texture rather than being the sheet itself.
        // The pane's position must be BOUNDED. `slide` grows without limit --
        // it is the texture's scroll, and that is right for texture -- but using
        // it for the sheet's centre walked all three panes clean out of the
        // frame within a few seconds, which is why the first cut looked like
        // debris rather than glass. The glass holds its place and drifts; the
        // texture slides across it. Each pane drifts on its own pair of slow
        // sines, which is what makes them slide against each other.
        float2 pcen = float2(0.082, -0.068) * (fi - 1.0)
                    + 0.050 * float2(sin(t * 0.31 + fi * 2.1),
                                     cos(t * 0.24 + fi * 1.3));
        float sd = ms_pane(uv, pcen, 0.20 - 0.26 * fi,
                           float2(0.255 - 0.020 * fi, 0.185 - 0.014 * fi), 0.055);
        float pane = 1.0 - smoothstep(0.0, 0.038, sd);
        // The front pane's edge is the bright line. One crisp contour is what
        // tells the eye there is glass in front of glass.
        float rimZ = sd / 0.020;
        float rim = exp(-rimZ * rimZ) * (1.0 - 0.55 * far);

        // THE SILHOUETTE, and this is the line the first cut did not have. A
        // soft threshold rather than a coverage floor: the scrim genuinely is
        // NOT THERE in its gaps, so there is somewhere for the thing behind to
        // be seen, and its boundary is soft enough to have no edge and definite
        // enough for the eye to find. That boundary is what the parallax
        // attaches to; without it three overlapping fields just average.
        //
        // The transition window is wide, and gets wider with depth. Narrow
        // windows make the gaps small and hard, and a small hard gap with the
        // bright thing behind showing through it is a SPECK -- the one shape
        // this whole family is forbidden. Wide windows give large soft openings,
        // which is also what a real scrim has, and the extra width on the deeper
        // ones is what makes them read as thinner gauze.
        float lo = 0.38 - 0.06 * far;
        float body = smoothstep(lo, lo + 0.34 + 0.06 * far, d);

        // Each scrim has its own brightness plane, dimmer with depth: they are
        // veils catching a little light, not light sources.
        // The glass has to have a body, not just a rim. With the fill this low
        // the panes read as wireframe boxes: the edge did its job so well it
        // became the whole object, and an outline is not a translucent sheet.
        float level = mix(0.36, 0.19, far);
        float lum = level * (0.55 + 0.45 * d);

        // Thinning the scrims is how the thing behind gets nearer, which is
        // legibility's other half.
        float opacity = mix(0.72, 0.46, far) * (1.0 - 0.34 * legibility);
        // The pane decides the shape and the noise only textures it. Letting the
        // noise silhouette cut holes in the glass as well was the first cut, and
        // three perforated rectangles overlapping read as debris rather than as
        // panes -- the edge stopped being continuous, which is the one thing the
        // edge was for.
        float alpha = pane * opacity * (0.55 + 0.45 * body);

        acc += (lum * alpha + rim * 0.30 * (0.45 + 0.55 * legibility)) * T;
        T *= (1.0 - alpha);
    }

    // WHAT IS BEHIND. Finer, higher in contrast, and much brighter than any
    // scrim, with no veil of its own -- it is the thing being veiled. It arrives
    // through whatever transmittance the gaps in the three scrims have left,
    // which is what makes it almost legible rather than either hidden or plain.
    float2 backSlide = float2(0.038, -0.023) * t;
    float bn = ms_fbm3(float3(q * 3.20 + backSlide, t * 0.039 + 51.0), 2, 2.03, 0.50);
    float behind = smoothstep(0.26, 0.92, clamp(0.5 + 1.60 * bn, 0.0, 1.0));
    // SUCCESS: THE VEILS PART. The scrims give up their opacity for a breath
    // and what has been almost legible all along is, briefly, plainly there.
    // Nothing is added: the transmittance simply goes to one, which is the
    // species' own physics saying the thing it has been withholding.
    float behindLight = behind * (0.70 + 0.46 * legibility);
    acc += behindLight * T;
    // SUCCESS: THE VEILS PART. For one breath the scrims give up the light they
    // were holding back -- the second term is exactly the amount they had been
    // absorbing, (1 - T), handed over. What has been almost legible all along is
    // briefly plainly there, and it arrives because the transmittance opened,
    // not because anything was added on top.
    acc += behindLight * (1.0 - T) * st.complete * 0.90;

    float e = acc * 1.30 * (1.0 + 0.34 * st.complete + 0.14 * st.settled);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 1.0, 0.34);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.62), position, pixelScale);
}

// MARK: - 7. Echo

// ECHO. A form answered by its own past.
//
// THE ONE WAY THIS FAILS is rings. Say "echo" and the reflex is a concentric
// ripple, and a concentric ripple is a sonar sweep: a set of clean circles that
// belong to a radar screen and not to this family. There is not a circle in
// this species. What repeats is an IRREGULAR MASS -- the same noise silhouette
// the pack builds everywhere else -- and it repeats by being DISPLACED along a
// heading, never by expanding about a centre.
//
// EACH REPETITION IS LATE, and that is the difference between an echo and a row
// of copies. A ghost samples the field at t - k * lag, so it shows the form as
// it WAS, not as it is. It is therefore not merely the source shifted over: it
// is a differently shaped thing, different by exactly as much as the form
// changed while the sound was away. Photograph it and the ghosts do not rhyme
// with the source, they remember it.
//
// EACH REPETITION IS SOFTER, and the softness costs nothing. A blurred edge is
// a WIDE THRESHOLD, so every ghost reads its silhouette through a wider window
// than the one in front of it. No second sampling, no blur pass, no taps: the
// fourth ghost's window is so wide that its smoothstep is nearly a straight
// line and what is left is a soft lobe, which is what a fourth echo should be.
//
// THE FAMILY DRIFTS AS ONE. The whole constellation is carried by a single slow
// wander, and the heading the ghosts trail along turns on a slow sine, so the
// trail swings instead of pointing in one direction forever. The step between
// repetitions is small next to the mass's own radius, so the ghosts OVERLAP
// heavily and the picture is one smeared form with a memory rather than a line
// of separate blobs -- which is the other way this species could have become
// dots, and the reason the step is 0.045 to 0.12 and not more.
[[ stitchable ]] half4 ms_echo(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float repeats = clamp(c0, 0.0, 1.0);   // how many answers come back
    float decay   = clamp(c1, 0.0, 1.0);   // how fast they give up
    float offset  = clamp(c2, 0.0, 1.0);   // how far, and how late, each one is
    float blur    = clamp(c3, 0.0, 1.0);   // how much softer each one gets

    MSState st = ms_state(stateIndex, stateTau);

    // THE SOURCE TRAVELS, AND THE ANSWERS LIE ON ITS PATH. This is the change
    // that made the species legible in three seconds, and it is a change of
    // composition rather than of rate.
    //
    // Before, the constellation sat in one place with a wandering heading, and
    // the ghosts were displaced along a direction that had nothing to do with
    // any motion -- so what a viewer saw was a lumpy field with some lumps
    // fainter than others, and the honest description was "it kind of shifts
    // around". An echo is not a set of copies beside a thing. It is what a
    // MOVING thing leaves behind it.
    //
    // So the source now runs a slow circle and the trail direction is the
    // TANGENT to that circle, which puts every ghost exactly on the arc the
    // source has just come through. The repetitions are literally following it,
    // along the path it took, and the eye reads that instantly and for free.
    // RESPONDING drives it round faster: the same figure, decisive.
    float phi = t * 0.42 * (1.0 + 0.90 * st.drive);
    float2 wander = 0.135 * float2(cos(phi), sin(phi));
    float2 dir = float2(-sin(phi), cos(phi));   // where it has just been

    // THE STEP IS SMALLER THAN THE FORM, always, and that is the whole
    // balance of this species. Push the repetitions apart far enough to read
    // them individually and they become separate soft blobs -- orbs, the thing
    // Murmur exists not to be, arrived at from a third direction. Keep them
    // closer than the mass is wide and the series reads the way a stroboscopic
    // photograph reads: one thing, several times, fading. What makes a
    // repetition legible is then its SHAPE recurring down the trail, not a gap
    // beside it.
    // SUCCESS: THE ANSWERS ARRIVE TOGETHER. The spacing collapses and every
    // repetition lands on its source at once -- the series, which spends its
    // life spread out and fading, briefly coincides. That is what a completed
    // pattern is for a thing made of repetitions.
    // The step grew with the figure. A crescent nearly 0.2 across with the old
    // 0.09 spacing simply overlapped itself into one thick crescent and the
    // series vanished; the rule is still that the step stays under the form's
    // size, but under is not the same as negligible.
    float step = (0.085 + 0.110 * offset) * (1.0 - 0.92 * st.complete);
    // SLIGHTLY late, and slightly is the operative word. The lag has to be
    // small next to the time the form takes to change, or each ghost is a
    // different shape and the series reads as lumps rather than as one thing
    // answered. Half a second against a form that turns over in about ten is
    // roughly a twentieth of a shape: recognisably the same mass, visibly not
    // the same instant.
    float lag  = 0.22 + 0.55 * offset;     // seconds between them
    float live = 1.2 + 2.8 * repeats;      // how far down the series we hear

    float4 fNear = ms_flourish(t, 66.0);

    float acc = 0.0;
    for (int i = 0; i < 4; i++) {
        float k = float(i);
        // THE NEAR ANSWER: one repetition comes back closer than it should, and
        // a little more definite for it. Which one is hashed per gesture, so it
        // is a different member of the series each time. It is the series itself
        // misbehaving rather than a new thing appearing.
        float near = (abs(k - (1.0 + floor(fNear.z * 3.0))) < 0.5) ? fNear.x : 0.0;
        float2 c = wander - dir * (step * k * (1.0 - 0.55 * near));
        float2 p = (uv - c) / S;

        // The lateness. This is the line that makes it an echo.
        float tk = t - lag * k;

        // THE FORM IS EXTENDED, NOT COMPACT, and this is the hard-won line.
        // Every attempt to give this species a tidy single mass -- a gaussian
        // body, a perturbed distance field, a lower-frequency silhouette --
        // ended at the same place: an ORB. A compact form centred in a circle IS
        // an orb, however irregular you make its outline, because the circle
        // around it supplies the symmetry the form is missing. The only shape
        // that survives a circular frame in this family is a broad irregular
        // field that does not have a centre, so that is what repeats here: the
        // same threshold-of-noise the pack uses everywhere, read through a wide
        // shallow limit that keeps it off the rim and otherwise lets the
        // silhouette do all of the drawing.
        // THE CRESCENT, and it is the figure. The mass had to become an object
        // with a name, and every compact object tried in earlier waves came out
        // an orb, because a filled round blob inside a round frame is one. A
        // crescent is not: it has two horns, a concave side and a direction, and
        // repeated down a trail it reads instantly as ONE SHAPE SAID THREE
        // TIMES. It is a disc with a second disc bitten out of it -- two lengths
        // and no new taps.
        float2 pc = uv - c;
        float cres = (1.0 - smoothstep(0.155, 0.235, length(pc)))
                   * smoothstep(0.090, 0.185,
                                length(pc - dir * 0.072 - float2(dir.y, -dir.x) * 0.042));

        float d = 0.5 + 1.35 * ms_fbm3(float3(p * 2.35, tk * 0.105), 2, 2.03, 0.55);

        // Softer with every repetition, and the softness is free: a blurred
        // edge IS a wide threshold. By the fourth ghost the window is wider than
        // the field's whole range, so what is left is a soft lobe -- which is
        // what a fourth echo should be. No second sampling and no blur pass.
        float w = (0.20 + (0.24 + 0.52 * blur) * k) * (1.0 - 0.26 * near)
                * (1.0 - 0.55 * st.complete);
        float mass = smoothstep(0.56 - w, 0.56 + w, d);

        // Wide and shallow. Its only job is to keep the ghost away from a rim
        // it should never reach; the moment it is tight enough to decide the
        // outline, the species is an orb again.
        // The crescent IS the limit now. The wide shallow fall that used to keep
        // an amorphous field off the rim has nothing left to keep off, because
        // the figure carries its own boundary.
        float body = cres;

        // 0.66 is the source's own ceiling. An echo is a quiet thing: if the
        // loudest member of the series is already at the top of the rail there
        // is nowhere for the answers to be quieter, and the series flattens.
        // The source's crescent is the key structure and reaches cream; each
        // answer behind it is amber, then shadow, which is what makes the rhythm
        // read as a trail rather than as three equal shapes.
        acc += (0.32 + 0.68 * mass) * body * 1.34 * pow(mix(0.70, 0.26, decay), k)
                          * smoothstep(0.0, 1.0, live - k);
    }

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, acc * (1.0 + 0.62 * st.complete + 0.16 * st.settled),
                          glow, 0.0, 1.0, 0.32);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 8. Glyph

// GLYPH. Almost-writing.
//
// THE ONE WAY THIS FAILS is letters. A shader that draws a legible character is
// a gimmick, it is wrong the second time you look at it, and it dies in review.
// So there is no alphabet here, no glyph table, no letterform of any kind. What
// there is is the PHYSICS OF A STROKE, and strokes that never get far enough to
// become anything.
//
// HOW A STROKE IS MADE, and it is one idea: a stroke is what a blob becomes
// when you look at it in a squashed frame. The domain is compressed along the
// direction the hand is pulling and stretched across it -- a third along, nearly
// three times across -- so the field's own round features come out long and
// narrow. Take the crest of that field rather than its body and what is drawn is
// a mark with weight that varies down its length, which is what a loaded brush
// does. The pulling direction is itself a slow noise field, so marks cross each
// other at every angle instead of combing in one, and that is the difference
// between handwriting and hatching.
//
// HOW IT NEVER RESOLVES, and this is the species rather than a detail. A second,
// much faster field is the clock, and the presence read off it is two smoothsteps
// whose EDGES OVERLAP: the falling edge begins before the rising edge has
// finished. A mark therefore starts dissolving before it has finished forming,
// and its peak lands around two thirds rather than at one. It is not a fade in
// and a fade out with a hold between them -- there is no hold, and there is
// never a moment where the thing is fully there. That is meaning trying to
// arrive, stated as an inequality between two thresholds.
//
// WHAT IT IS NOT. ms_cipher is a latent field lit by a passing attention: smoke
// with a reveal, and its shapes are broad islands. This is gestural: narrow,
// directional, struck rather than uncovered, and its dark is empty page rather
// than unlit field. It is also new writing FORMING and not old writing
// surfacing, so nothing here is ever recovered from underneath -- every mark is
// made now, in front, and lost.
[[ stitchable ]] half4 ms_glyph(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float marks     = clamp(c0, 0.0, 1.0);   // how much is being written at once
    float formation = clamp(c1, 0.0, 1.0);   // how far a mark gets
    float dissolve  = clamp(c2, 0.0, 1.0);   // how quickly it goes
    float ink       = clamp(c3, 0.0, 1.0);   // how wet the brush is

    MSState st = ms_state(stateIndex, stateTau);

    // RESPONDING: the hand moves ACROSS THE PAGE. A steady advection of the
    // writing domain, so marks are laid down and left behind instead of
    // appearing and vanishing in place -- the difference between someone
    // thinking with a pen in their hand and someone writing a reply.
    float2 q = uv / S - float2(0.62, 0.16) * (t * 0.34 * st.drive);

    // THE HAND. The angle the stroke is being pulled at, here, now.
    // The frequency matters as much as the amplitude: a slowly turning hand
    // writes every mark in a region at the same angle, which is hatching, not
    // handwriting. This turns over about half a frame, so marks cross.
    float ang = 2.80 * ms_fbm3(float3(q * 1.35, t * 0.052), 2, 2.00, 0.50) + 0.50;
    float2 d = float2(cos(ang), sin(ang));
    float2 e = float2(-d.y, d.x);

    // THE STROKE. Compressed along the pull, stretched across it.
    float fq = 1.50 + 2.40 * marks;
    // THE NEAR WORD: somewhere on the page the hand presses on and a mark runs
    // further than the others before it goes. Two things happen inside one soft
    // patch, and both are form. The domain's compression ALONG the pull tightens,
    // so the stroke extends instead of ending -- a longer, more continuous mark.
    // And the presence window's falling edge is delayed, so that mark gets
    // nearer to formed than this species otherwise allows.
    //
    // It still never resolves. There is no letterform anywhere in the
    // construction to resolve INTO: a longer stroke is a longer stroke. And the
    // delayed edge takes the peak from about 0.46 to about 0.65, which is closer
    // to arriving and still not arrival. The gesture makes the almost more
    // almost; it does not make it a word.
    float4 fWord = ms_flourish(t, 73.0);
    float wordA = fWord.z * 6.2831853;
    float wz = length(uv - 0.22 * float2(cos(wordA), sin(wordA))) / 0.32;
    float word = fWord.x * exp(-wz * wz);

    // SUCCESS: ONE FULL CONFIDENT STROKE. The compression along the pull drops
    // right down, so the mark runs the length of the frame instead of petering
    // out, and below the presence window is opened so it actually completes.
    //
    // It is still not a letter and it cannot become one: there is no letterform
    // anywhere in this construction to resolve INTO. A completed stroke is a
    // completed stroke. This is the one moment the species is allowed to finish
    // what it starts, and finishing a stroke is not writing a word.
    // The arrival is LOCAL. Applied across the whole frame it lengthens every
    // stroke at once and opens every mark's window at once, and the page floods
    // to a flat sheet of ink -- which is not a completed stroke, it is no
    // strokes at all. One stroke completing needs somewhere for it to be, so the
    // arrival lives in a patch about a quarter of the frame across and the rest
    // of the page goes on almost-writing around it.
    float scz = length(uv - float2(-0.05, 0.02)) / 0.24;
    float arrive = st.complete * exp(-scz * scz);

    float alongC = 0.34 * (1.0 - 0.45 * word) * (1.0 - 0.52 * arrive);
    float2 sq = float2(dot(q, d) * alongC, dot(q, e) * 2.70) * fq;
    float m = ms_fbm3(float3(sq, t * 0.115), 2, 2.03, 0.52);

    // The crest, not the body: a mark, not a smear. Wet ink lays a fatter line.
    // The stroke figure is kept as approved; what changes is that its SPINE now
    // reaches the top of the rail. `core` is the centre line of the mark, where
    // a brush presses hardest, raised to a high power so it is a thin bright
    // filament inside an amber stroke rather than a general lightening of the
    // whole thing -- which would flatten the three tiers back into two.
    float wet = mix(4.60, 2.60, ink);
    float across = clamp(abs(m) * wet, 0.0, 1.0);
    float stroke = pow(1.0 - across, 1.55);
    float core = pow(1.0 - across, 6.5);
    // What the wet brush leaves either side of where it actually touched.
    float bleed = (1.0 - clamp(abs(m) * wet * 0.42, 0.0, 1.0)) * 0.22 * ink;

    // THE LIFE. Two smoothsteps whose edges overlap, so the peak is about two
    // thirds and there is no moment of arrival anywhere in the cycle.
    // The window is NARROW as well as overlapped. Narrow so that most of the
    // page is bare at any instant -- writing is marks with paper between them,
    // and the first cut, whose window was open over half the field's range,
    // came out as a single blown sweep with no marks in it at all. Overlapped
    // so the peak lands near 0.46: there is no value of L at which a mark is
    // fully formed, which is the species.
    float L = 0.5 + 1.90 * ms_fbm3(float3(q * 1.05, t * (0.300 + 0.34 * st.drive)),
                                   2, 2.00, 0.50);
    float peak = 0.30 + 0.30 * formation;
    float w2 = mix(0.20, 0.12, dissolve);
    float rise = smoothstep(peak - 0.16, peak + 0.10, L);
    // SUCCESS delays the FALLING edge only, and does not touch the rising one.
    // That distinction is the whole fix: opening the rise lets MORE marks be
    // present at once, which floods the page; delaying the fall lets the marks
    // that were already forming actually FINISH. One stroke completing, not a
    // page filling. The peak goes from about 0.46 to about 0.85 inside the
    // arrival's patch, which is a confident mark and still short of a resolved
    // one -- and there is no letterform in the construction to resolve into.
    float fall = 1.0 - smoothstep(peak - w2 * 0.50 + 0.060 * word + 0.110 * arrive,
                                  peak + w2 + 0.100 * word + 0.260 * arrive, L);
    // A page that has been written on is never quite blank between marks, and
    // an indicator that empties out for a second and a half reads as switched
    // off. The residue is the ink already in the paper: the same stroke
    // structure at a tenth of its weight, so what is left behind is the ghost
    // of the writing and not a haze.
    float presence = max(rise * fall, 0.11 * smoothstep(0.10, 0.45, L));

    float en = (stroke * (0.62 + 0.48 * ink) + core * 0.75 + bleed) * presence;

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, en * 1.70 * (1.0 + 0.26 * st.complete + 0.13 * st.settled),
                          glow, 0.0, 1.0, 0.32);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.58), position, pixelScale);
}
