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
//   ms_veil         three translucent sheets sliding at different rates. What is
//                   behind stays almost legible: parallax as depth of thought.
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
// sees is material moving, not a light being turned up and down. Two species
// have a slow structural cycle (the loom's tautness, the tuning's lock) and in
// both the cycle IS the concept, not a lamp on a timer.
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
    float en = clamp(ms_knee(max(e, 0.0) * (0.35 + 0.65 * G), 0.82), 0.0, 1.0);
    float tRail = clamp(base + span * en, 0.0, 1.0);
    float3 col = ms_shade(pal, tRail);
    // Emission is gated high on the rail so the ground never lifts: only
    // material that has actually reached the tone gives off light of its own.
    return col * (1.0 + emis * G * smoothstep(0.55, 0.98, tRail));
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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float flock    = clamp(c0, 0.0, 1.0);   // how much material is in the air
    float turn     = clamp(c1, 0.0, 1.0);   // how hard the mass banks and rolls
    float cohesion = clamp(c2, 0.0, 1.0);   // sheet thickness: haze to crease
    float sky      = clamp(c3, 0.0, 1.0);   // the dusk behind it

    // THE BANK.
    float bank = turn * (0.62 * sin(t * 0.107) + 0.31 * sin(t * 0.181 + 1.7));

    // THE ROLL. 0.26 is roughly where the mass's own body ends, so the inside
    // leads the outside, which is the way round a real roll goes.
    float r = length(uv);
    float2 q = ms_rot(uv, bank * (1.0 + 1.35 * turn * (0.26 - r))) / S;

    // The drag: one warp field along the tangent of the turn, because that is
    // the direction the flock's own motion carries its material.
    float2 tangent = float2(-uv.y, uv.x) / max(r, 1e-3);
    float warp = ms_fbm3(float3(q * 1.35 + float2(9.7, 3.1), t * 0.055), 2, 2.00, 0.50);
    float2 qw = q + tangent * (warp * (0.22 + 0.30 * flock) / S);

    // The sheet.
    float n = ms_fbm3(float3(qw * 2.85, t * 0.085), 3, 2.03, 0.52);
    float thick = mix(0.46, 0.13, cohesion);
    float sheet = exp(-abs(n) / thick);

    // THE BODY. A flock has an outline and it is not the frame's. A super
    // gaussian at 0.285 with a slowly wandering centre: broad enough that a 20 pt
    // indicator is one clear gesture, tight enough that the containment below
    // never has to cut anything that was still bright.
    float2 bc = uv - 0.070 * float2(sin(t * 0.083), cos(t * 0.061));
    float body = exp(-pow(length(bc) / 0.285, 2.3));
    float dens = body * (0.20 + 0.80 * sheet) * (0.42 + 0.58 * flock);

    float skyN = ms_fbm3(float3(q * 0.75, t * 0.031), 2, 2.00, 0.50);
    float dusk = sky * (0.055 + 0.075 * (0.5 + skyN)) * (1.0 - 0.55 * dens);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, dens + dusk, glow, 0.0, 0.80, 0.55);

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
    float c0, float c1, float c2, float c3, float epoch
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

    // The pitch. 14 to 34 puts between two and five and a half cycles across the
    // indicator, which is the band where a weave reads as cloth at 20 pt and
    // still has structure worth looking at across 300 pt. Higher is a comb.
    float K = mix(14.0, 34.0, threads);
    float aa = ms_aa(K / S, size, pixelScale);

    // THE LOOM'S BEAT: taut, then eased, then taut. Fifty five seconds.
    float beat = 0.5 + 0.5 * sin(t * 0.1142);
    float taut = clamp(tension * (0.42 + 0.58 * beat), 0.0, 1.0);
    float wander = mix(1.15, 0.20, taut);

    // Each family wanders along its OWN threads, so threads bend over their
    // length instead of the whole sheet sliding.
    float w1 = ms_fbm1(dot(q, d2) * 1.9 + t * 0.055, 3, 4.0);
    float w2 = ms_fbm1(dot(q, d1) * 1.9 - t * 0.041, 3, 61.0);

    // Time enters as a slow crawl of the phases, which is the cloth being fed
    // through the loom, not a brightness on a timer.
    float ph1 = dot(q, d1) * K + w1 * wander * 2.6 - t * 0.34;
    float ph2 = dot(q, d2) * K + w2 * wander * 2.6 + t * 0.27;

    float s1 = sin(ph1), s2 = sin(ph2);
    float b1 = mix(0.5, 0.5 + 0.5 * s1, aa);
    float b2 = mix(0.5, 0.5 + 0.5 * s2, aa);
    float cloth = 0.5 * (b1 + b2) + taut * 0.62 * (b1 * b2 - 0.25);

    // The bolt is not uniform: a slow broad field thickens and thins it, so the
    // cloth has weight in some places and is nearly sheer in others.
    float bolt = 0.62 + 0.55 * (0.5 + ms_fbm3(float3(q * 1.05, t * 0.036), 2, 2.00, 0.50));

    // THE SHEEN. cos(phase) is the slope; the fixed vector is the light.
    float slope = 0.72 * cos(ph1) * aa - 0.58 * cos(ph2) * aa;
    float spec = pow(clamp(0.5 + 0.5 * slope, 0.0, 1.0), 5.0);

    // Handed over uncapped: the crossings and the sheen together pass 1 in the
    // brightest places, and ms_lit's knee is where that is meant to be resolved.
    float e = cloth * bolt * (0.78 + 0.42 * taut) + sheen * 0.34 * spec * cloth;

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 0.78, 0.60);

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
    float c0, float c1, float c2, float c3, float epoch
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
    float lat = ms_fbm3(float3(q * 2.60, t * 0.048), 4, 2.03, 0.52);

    float lobes  = clamp(0.5 + 1.15 * lat, 0.0, 1.0);
    float crease = 1.0 - clamp(abs(lat) * 2.30, 0.0, 1.0);
    float psi = mix(lobes, crease, structure);

    // THE ATTENTION. Slower and wider as dwell rises.
    float rate = mix(0.46, 0.13, dwell);
    float2 ac = 0.24 * float2(sin(t * rate * 0.83), sin(t * rate * 0.61 + 2.1));
    float rad = mix(0.235, 0.315, dwell);
    float ad = length(uv - ac) / rad;
    float att = exp(-ad * ad);

    // The threshold. High everywhere by default -- almost nothing crosses it --
    // and pulled down where attention is. The 0.30 band above it is the softness
    // of the coastline: narrower and the islands get a hard edge, which organic
    // forms are never allowed.
    float thr = mix(0.88, 0.28, clamp(reveal * att + scatter * 0.20, 0.0, 1.0));
    float e = smoothstep(thr, thr + 0.30, psi);

    // The residue, so the dark is a field and not a hole.
    e = max(e, scatter * 0.22 * smoothstep(0.52, 0.96, psi));

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 0.82, 0.65);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 4. Tuning  (arc)

// TUNING. Static finding the station.
//
// This is the pack's arc, and the arc is a SPECTRUM narrowing. Four octaves are
// summed with gaussian weights over octave index -- a passband. At birth the
// band is wide, all four octaves are present at once, and the field is
// broadband: hiss, isotropic, no direction and no scale of its own. As the
// settle law runs, the band narrows onto one octave and the domain is squeezed
// along the station's axis until the field varies almost only ACROSS it. Wide
// band plus isotropic domain is static. Narrow band plus anisotropic domain is a
// line. Nothing is faded in or out; what changes is which spatial frequencies
// the field is allowed to contain, which is exactly what tuning a receiver does.
//
// THE ARC IS A LAW, NOT AN ANIMATION. ms_settle_law states the scramble SPEED
// and hands back its exact integral, so the domain's position at any t is the
// position it would have reached, and the shader is deterministic under a
// screenshot rig or a scrubbed slider. `epoch` restarts it. The still-moving
// fraction e drives the coherence directly: coherence is 1 - e, so the picture
// and the motion arrive together instead of being two timelines that have to be
// kept in step.
//
// SETTLED IS NOT STOPPED, and this species says so three ways. The law's floor
// keeps the field boiling at a twentieth of its birth rate forever. The station
// line is not straight -- it is displaced by a one-dimensional fBm that keeps
// wandering, so the band breathes along its length like a needle holding a
// signal. And the HISS never goes: a receiver locked onto a station still hisses
// underneath it, and a thinking indicator that reaches perfect silence has
// stopped thinking.
//
// LOCK is how narrow the band is allowed to get. At zero the station never quite
// arrives and the field stays broad, which is a legitimate and rather beautiful
// setting; at one it locks hard.
[[ stitchable ]] half4 ms_tuning(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float band  = clamp(c0, 0.0, 1.0);   // which scale the station sits on
    float lock  = clamp(c1, 0.0, 1.0);   // how completely it narrows
    float hiss  = clamp(c2, 0.0, 1.0);   // the floor that never leaves
    float drift = clamp(c3, 0.0, 1.0);   // the settled needle's wander

    // THE ARC. Six seconds is the tempo of an answer arriving: long enough that
    // the search is legible, short enough that a chat UI is not made to wait.
    // The house rate dial stays OUT of it, the way the pour keeps exhaleTime in
    // real seconds, so a slower field still settles when it says it will.
    float tau = max(time - epoch, 0.0);
    float3 law = ms_settle_law(tau, 6.0);
    float coh = clamp((1.0 - law.z) * (0.34 + 0.66 * lock), 0.0, 1.0);
    float scroll = law.y * max(speed, 0.0);

    // Six degrees off level. A station is a line, but a line at exactly zero
    // degrees inside a circle reads as a rule someone drew in the UI.
    float2 pq = ms_rot(uv, 0.105) / S;

    // THE NEEDLE. The band's centre line is displaced along its length by a
    // one-dimensional fBm that never stops moving, so a locked station still
    // breathes. drift sets how far.
    float needle = ms_fbm1(pq.x * 1.35 + t * 0.085, 3, 17.0) * (0.020 + 0.055 * drift);
    float across = pq.y - needle;

    // THE PASSBAND. Wide at birth, one octave wide when locked.
    float centre = 0.35 + 2.10 * band;
    float width = mix(2.30, 0.55, coh);
    // The squeeze along the station's axis: at birth the domain is isotropic and
    // the field has no direction; locked, x barely moves it and every octave is
    // a striation running along the line.
    float xs = mix(1.0, 0.09, coh);
    float f0 = mix(3.2, 8.4, band);

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
                                    across * f0 * oct,
                                    scroll * (0.42 + 0.30 * float(i)) + float(i) * 19.0));
        wsum += w;
    }
    float v = acc / max(wsum, 1e-4);

    // THE ENVELOPE. Broadband energy fills the frame; a station does not. As
    // coherence rises the energy collects into a band 0.17 wide about the line.
    float ax = across / 0.17;
    float env = mix(1.0, exp(-ax * ax), coh);

    // THE HISS. A fine field, gated on the same resolution test, so it stays a
    // noise FLOOR at every size: audible under the station, never a grain of
    // sand on the glass and never a mote.
    float hz = ms_noise3(float3(pq * 11.0, scroll * 1.7 + 41.0));
    float floorHiss = hiss * (0.055 + 0.075 * (0.5 + hz))
                    * mix(1.0, 0.62, coh) * ms_aa(6.2831853 * 11.0 / S, size, pixelScale);

    // The band brightens as it locks -- energy that was spread over the whole
    // frame is now in one place, which is what a receiver actually does with it.
    float e = env * (0.16 + 0.84 * clamp(0.5 + 1.25 * v, 0.0, 1.0))
                  * (0.55 + 0.45 * coh) + floorHiss;

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 0.84, 0.70);

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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float pathways  = clamp(c0, 0.0, 1.0);   // how finely the medium is divided
    float pulseRate = clamp(c1, 0.0, 1.0);   // how often an impulse passes
    float afterglow = clamp(c2, 0.0, 1.0);   // bleed into the medium, and wake
    float branch    = clamp(c3, 0.0, 1.0);   // regions, or a branching system

    float2 q = uv / S;

    // THE MEDIUM.
    float fq = mix(1.70, 3.30, pathways);
    float3 pm = float3(q * fq, t * 0.045);
    float n = ms_fbm3(pm, 3, 2.03, 0.55);
    float open = clamp(0.5 + 1.30 * n, 0.0, 1.0);
    float crease = 1.0 - clamp(abs(n) * 3.10, 0.0, 1.0);
    float chan = mix(open, crease, branch);

    // The same medium at half the frequency: what the light looks like once it
    // has scattered out of a channel and into the material either side. Not a
    // blur of `chan`, and not pretending to be one -- it is the broad component
    // of the same field, which is what a scattered version of it actually is.
    float halo = clamp(0.5 + 1.15 * ms_fbm3(pm * 0.55 + 13.0, 2, 2.00, 0.50), 0.0, 1.0);

    // THE PHASE. The bend dominates the straight term on purpose: wavefronts
    // that follow the medium read as transport through it, and a straight front
    // reads as a wipe.
    float bend = ms_fbm3(float3(q * 1.15, t * 0.030), 2, 2.00, 0.50);
    float phase = dot(q, float2(0.62, 0.38)) * 3.20 + bend * 5.60;

    float rate = mix(0.30, 1.25, pulseRate);
    float th = phase - t * rate * 2.0;
    float skew = th + 0.55 * sin(th);                 // steep front, long wake
    float k = mix(4.20, 1.75, afterglow);             // and how long
    float pulse = exp(k * (cos(skew) - 1.0));

    float e = clamp(chan * (0.13 + 0.87 * pulse)
                    + afterglow * 0.30 * halo * pulse * chan, 0.0, 1.0);

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 0.82, 0.75);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 6. Veil

// VEIL. Layers of translucency sliding.
//
// Three sheets, front to back, composited the way translucency actually
// composites: each contributes its own light times what is left of the light
// path in front of it, and takes its own bite out of the transmittance on the
// way. T *= (1 - alpha) is not a stylistic choice, it is the reason the picture
// has depth -- the back sheet is dimmed by exactly the sheets in front of it,
// per pixel, which is the thing a stack of blended layers cannot fake.
//
// THE PARALLAX. Depth is not drawn here, it is INFERRED, and the eye does it for
// free from two cues. Further sheets slide slower, and further sheets are
// sampled at a higher spatial frequency because more of them fits in the same
// angle. Nothing is scaled and nothing is blurred; the cues are enough.
//
// WHAT IS BEHIND is meant to be ALMOST legible, which is a narrow target: fully
// legible and the veils are pointless, illegible and it is fog. So the rearmost
// sheet is the one with contrast, and the two in front are broad and only partly
// opaque -- about a third each, which leaves a little under half the back sheet
// arriving. `legibility` moves both ends of that: it raises the back sheet's
// contrast and thins the front two, so the answer behind the curtain comes
// nearer without ever quite arriving.
//
// `layers` is a separation, not a count. The loop is fixed at three, because a
// variable loop is not allowed and because three is what reads: at zero the
// three sheets converge onto nearly the same scale and rate and the picture is
// one soft veil, and at one they pull apart into three plainly different depths.
[[ stitchable ]] half4 ms_veil(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float layers     = clamp(c0, 0.0, 1.0);   // how far apart the depths sit
    float parallax   = clamp(c1, 0.0, 1.0);   // how differently they slide
    float legibility = clamp(c2, 0.0, 1.0);   // how near the back one comes
    float drift      = clamp(c3, 0.0, 1.0);   // the sliding itself

    float2 q = uv / S;
    float sep = 0.35 + 0.65 * layers;
    float base = 0.055 + 0.135 * drift;

    float acc = 0.0;     // light gathered, already attenuated by what is in front
    float T = 1.0;       // what is left of the light path
    for (int i = 0; i < 3; i++) {
        float fi = float(i);

        // Deeper sheets: finer on screen, slower across it, and each on its own
        // heading, so this is parallax and not one translation of three copies.
        float f = 2.10 * (1.0 + 0.55 * fi * sep);
        float rate = base / (1.0 + 1.70 * fi * parallax);
        float head = 0.30 - 0.34 * fi;
        float2 slide = float2(cos(head), sin(head)) * (rate * t);

        float n = ms_fbm3(float3(q * f + slide, t * 0.022 + fi * 7.3), 2, 2.03, 0.50);
        float d = clamp(0.5 + 1.25 * n, 0.0, 1.0);

        // The back sheet carries the contrast; the two in front are films, and
        // legibility is only allowed to sharpen the one behind.
        float far = fi * 0.5;                       // 0, 0.5, 1 front to back
        float contrast = mix(0.70, 1.20 + 0.75 * legibility, far);
        float lum = clamp((d - 0.5) * contrast + 0.5, 0.0, 1.0);

        // A veil is mostly present even where it is thin, so the coverage floor
        // is a quarter rather than zero: at zero the front sheets stop occluding
        // in their thin places and the stack loses the depth it was built for.
        // Thinning the two in front is how the thing behind gets nearer, which
        // is legibility's other half.
        float opacity = mix(0.36 * (1.0 - 0.38 * legibility), 0.46, far * far);
        float alpha = mix(0.25, 1.0, smoothstep(0.20, 0.85, d)) * opacity;

        acc += lum * alpha * T;
        T *= (1.0 - alpha);
    }

    // Normalised against what a single fully present sheet would give, so the
    // stack does not read dimmer than one veil merely because it is three.
    float e = acc * 2.10;

    MSPalette pal = ms_palette(inkColor, toneColor, hueShift, depth);
    float3 field = ms_lit(pal, e, glow, 0.0, 0.76, 0.50);

    float3 inkLin = ms_srgb_to_linear(float3(inkColor.rgb));
    return ms_finish(field, inkLin, ms_containment(uv, 0.62), position, pixelScale);
}
