// The Ink pack. Six thinking indicators made of ink and paper.
//
//   mi_bloom      a drop of ink meeting wet paper: a front that runs out of
//                 ink and stops, with a fringe that never stops moving.
//   mi_marbling   a combed sheet: laminar folds raked past each other, the
//                 suminagashi operator done as a shear rather than a warp.
//   mi_wick       capillary rise: ink climbing fibre against gravity to the
//                 height the pores can hold, and no further.
//   mi_strata     sediment finding its level: turbidity that laminates.
//   mi_halation   a dark mass wearing its own light, the way a dense negative
//                 wears the light that scattered back through the emulsion.
//   mi_pool       ink already at rest in a dish, meniscus alive. The stillest
//                 thing in the set.
//   mi_feather    ink that has stopped obeying the drop and started obeying the
//                 sheet: a directional bleed advancing as a comb of hairs.
//   mi_palimpsest a scraped page giving up what it used to say, in rows, and
//                 taking it back before it can be read.
//
// WHAT THE FAMILY IS. These are the ink relatives of the Pour: same blood,
// warm liquid light on a near-black ground, every value generated per pixel out
// of a field and walked through one OKLAB rail. What they do NOT share is the
// pour's body. The pour is a falling sheet; nothing here falls. The verbs in
// this pack are FLOW and SETTLE, and the physics is ink physics: fronts,
// capillarity, lamination, sediment, surface tension. If a shader in this file
// starts to read as vertical streaming metal it has drifted back into its
// parent and should be killed.
//
// WHY THE KIT IS COPIED AND NOT LINKED. Cross-file Metal linkage is not
// guaranteed, and the house has been here before: the kit is copied out of
// FieldLab.metal VERBATIM under an mi_ prefix, comments included, because the
// reasoning in those comments is the part worth carrying. Copied unchanged
// except for the name:
//
//   mi_hash, mi_grad3, mi_noised3, mi_noise3, MI_ROT, mi_fbmd3, mi_fbm3,
//   mi_srgb_to_linear, mi_linear_to_srgb, mi_linear_to_oklab,
//   mi_oklab_to_linear, mi_lch, MIPalette, mi_palette, mi_shade, mi_out,
//   mi_knee
//
// The 1D value-noise kit (fl_hash1, fl_vnoise1, fl_fbm1) is deliberately NOT
// here: nothing in this pack wants a wandering scalar on a line badly enough to
// pay for a second noise basis, and copying it would only leave dead code
// behind a prefix. Where a 1D function is wanted (the wick's front, the pool's
// shore) it is taken as a SLICE of the 3D field instead, which costs one tap
// and buys something the 1D kit cannot give: the slice can be moved through the
// third coordinate, so the function evolves IN PLACE instead of sliding
// sideways. A wet line that slides sideways is a conveyor belt. A wet line that
// changes in place is capillary action.
//
// THE ONE THING EVERY SHADER HERE DOES THAT THE POUR DOES NOT. The Murmur view
// clips to a circle, and a clip is a guillotine: whatever the field is doing at
// length(uv) = 0.5 gets cut on a hard rule. So every function in this file
// brings its light down to pure ink WELL inside that rim (mi_shore, 0.28 to
// 0.46) and composites over the ink itself, the pour's own mix(inkLin, drawn,
// containment). The clip then has nothing left to cut.
//
// BUDGET. These run at 46 pt in a chat and at 300 pt in the lab. Every function
// here spends at most three field taps a pixel, fBm at three octaves or fewer,
// every loop fixed-count. Frequencies are chosen against the SMALL size, not
// the large one: a 20 pt indicator on a 3x screen is 60 samples across, so a
// feature finer than about 1/15th of the frame has nothing left to stand on and
// turns into shimmer. Where that limit could not be respected honestly (the
// marbling veins) the shader band-limits itself with fwidth and dissolves the
// detail into the mass it belongs to, which is the Contour field's trick and
// the only correct answer to a line finer than a pixel.
//
// TEMPO, and this pack was retuned once on it. The first cut set its rates
// against the Pour, which is an ambient card a person glances at, and against
// that reference everything here was correct and everything here was too slow.
// These are THINKING indicators: they stand in for attention, not for weather,
// and attention has a pulse. So the internal rates were lifted between about
// 1.4x and 1.9x, per style, and the rule for spending that was CARRIER BEFORE
// DETAIL. Each species has one motion that carries its gesture (the bloom's
// fringe, the marbling rakes, the wick's wet line, the strata rock, the
// halation morph) and one that only textures it (the mottle, the sheet, the
// grain, the convection, the tremor). The carriers took the larger share and
// the details the smaller, which is what makes the set read faster without
// reading busier: more speed on the same number of things, rather than more
// things. Pool took the smallest lift of the six on purpose, because being the
// stillest of the set is not a tuning of that species, it is the species.
//
// `speed` still means what it always meant. 1.0 is the designed tempo; what
// changed is what the design IS.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's, verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mi_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mi_grad3(int3 c) {
    uint h = mi_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// Gradient noise and its analytic gradient, in one evaluation.
/// Returns (value, d/dx, d/dy, d/dz). Quintic interpolation, so the derivative
/// is itself continuous: lighting built on it has no facets at cell walls.
static float4 mi_noised3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
    int3 c = int3(i);

    float3 ga = mi_grad3(c + int3(0, 0, 0));
    float3 gb = mi_grad3(c + int3(1, 0, 0));
    float3 gc = mi_grad3(c + int3(0, 1, 0));
    float3 gd = mi_grad3(c + int3(1, 1, 0));
    float3 ge = mi_grad3(c + int3(0, 0, 1));
    float3 gf = mi_grad3(c + int3(1, 0, 1));
    float3 gg = mi_grad3(c + int3(0, 1, 1));
    float3 gh = mi_grad3(c + int3(1, 1, 1));

    float va = dot(ga, f - float3(0.0, 0.0, 0.0));
    float vb = dot(gb, f - float3(1.0, 0.0, 0.0));
    float vc = dot(gc, f - float3(0.0, 1.0, 0.0));
    float vd = dot(gd, f - float3(1.0, 1.0, 0.0));
    float ve = dot(ge, f - float3(0.0, 0.0, 1.0));
    float vf = dot(gf, f - float3(1.0, 0.0, 1.0));
    float vg = dot(gg, f - float3(0.0, 1.0, 1.0));
    float vh = dot(gh, f - float3(1.0, 1.0, 1.0));

    float k1 = vb - va;
    float k2 = vc - va;
    float k3 = ve - va;
    float k4 = va - vb - vc + vd;
    float k5 = va - vc - ve + vg;
    float k6 = va - vb - ve + vf;
    float k7 = -va + vb + vc - vd + ve - vf - vg + vh;

    float value = va + k1 * u.x + k2 * u.y + k3 * u.z
                + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x
                + k7 * u.x * u.y * u.z;

    // Two contributions: the gradients blended by the same trilinear weights,
    // plus the interpolant's own rate of change through the corner values.
    float3 grad = ga
        + u.x * (gb - ga) + u.y * (gc - ga) + u.z * (ge - ga)
        + u.x * u.y * (ga - gb - gc + gd)
        + u.y * u.z * (ga - gc - ge + gg)
        + u.z * u.x * (ga - gb - ge + gf)
        + u.x * u.y * u.z * (-ga + gb + gc - gd + ge - gf - gg + gh)
        + du * float3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z,
                      k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x,
                      k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y);

    return float4(value, grad);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float mi_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mi_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mi_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mi_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mi_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mi_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mi_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mi_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mi_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse, which
/// is exactly what the chain rule below needs. Without it every octave stacks on
/// the same lattice axes and the field grows a visible plaid.
constant float3x3 MI_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

/// fBm carrying its own derivative. `mt` accumulates the transpose of the map
/// from the base domain to the current octave's domain, so each octave's
/// gradient is rotated back before it is summed. Returns (value, gradient).
static float4 mi_fbmd3(float3 p, int octaves, float lacunarity, float gain) {
    float3x3 rotT = transpose(MI_ROT);
    float3x3 mt = float3x3(1.0);
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    float3 grad = float3(0.0);
    for (int i = 0; i < octaves; i++) {
        float4 n = mi_noised3(q);
        value += amp * n.x;
        grad += amp * (mt * n.yzw);
        amp *= gain;
        q = lacunarity * (MI_ROT * q);
        mt = lacunarity * (mt * rotT);
    }
    return float4(value, grad);
}

static float mi_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * mi_noise3(q);
        amp *= gain;
        q = lacunarity * (MI_ROT * q);
    }
    return value;
}

static inline float3 mi_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mi_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mi_linear_to_oklab(float3 c) {
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

static inline float3 mi_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mi_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the day tone the ribbon wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MIPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MIPalette mi_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mi_linear_to_oklab(mi_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mi_linear_to_oklab(mi_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MIPalette p;
    p.s0 = ink;
    p.s1 = mi_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mi_lch(L, C, h);
    p.s3 = mi_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mi_out does the encoding.
static float3 mi_shade(MIPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return mi_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mi_out(float3 linearRGB, float2 pixel) {
    float3 c = mi_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mi_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// Copied with the rest of the kit, and it arrived late. The first cut of this
/// file deliberately left the 1D kit out because nothing here wanted a
/// wandering scalar on a line. The play wave brought this one function back on
/// its own, because a well-mixed number from an integer index is exactly what
/// an aperiodic clock is built out of. The value noise and the fBm that
/// FieldLab stacks on top of it are still not copied, because still nothing
/// here calls them.
static inline float mi_hash1(float cell, float lane) {
    return float(mi_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

// MARK: - The pack's own frame
//
// Three small things every shader in this file shares, and nothing else: there
// is no mi_render here, because unlike the Pour's five mutations these six are
// not one material. They are six materials in one ecosystem, and a shared body
// would be a lie about what they are.

/// The frame, centred, aspect preserved. Dividing by the SHORT side is what
/// makes a 46 pt indicator and a 300 pt one the same picture at two sizes
/// rather than two compositions, and it keeps the field centred in a non-square
/// host if one ever mounts these outside the circle.
static inline float2 mi_uv(float2 position, float2 size) {
    return (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
}

/// THE SHORE. The view clips to a circle at length(uv) = 0.5 and a clip is a
/// hard edge; organic forms in this house never have those. So the light is
/// gone before the rim ever arrives: whole inside 0.28, nothing left by 0.46,
/// smoothstep across the gap so the falloff itself never draws a ring.
///
/// The band is wide on purpose. A tight shore reads as a disc with a cut edge
/// at 20 pt, which is the exact failure the clip was supposed to hide; 0.18 of
/// frame is eight points of fade on a 46 pt indicator and fifty on a 300 pt
/// one, which in both cases is a form dissolving rather than a form ending.
static inline float mi_shore(float2 uv) {
    // Pushed out from 0.28/0.46 when the orb law landed. The shore used to be
    // the thing that gave a field its shape; now the ORB is the shape and its
    // own limb is the soft edge, so the shore's only remaining job is to catch
    // whatever light gets past the presence before the clip does. Left where it
    // was it would have taken a quarter of the brightness off every orb's rim.
    return 1.0 - smoothstep(0.40, 0.49, length(uv));
}

// MARK: The orb
//
// THE ORB LAW. Every species in this pack is one compact centred presence that
// could plausibly BE the assistant, and the species is what that presence is
// MADE OF, never where it sits in a scene. So this is the stage, and there is
// only one of them: a unit sphere, seen head on, filling the cell.
//
// WHY THE SPHERE POINT IS THE WHOLE TRICK. Given a pixel, z = sqrt(1 - r^2)
// lifts the flat frame onto the front of a ball, and the resulting unit vector
// is simultaneously three things every species here needs: the surface normal
// for lighting, the point for sampling a field, and a coordinate that WRAPS.
// Sampling 3D noise at that point gives a field painted on the globe with no
// seam anywhere and no pole to unwrap around, and it foreshortens for free:
// equal steps across the sphere cover less and less screen as they approach the
// limb, which is exactly the compression that makes a flat circle read as a
// ball. Nothing else in this file has to know it is drawing a sphere.
//
// The limb dimming is the other half of that read. A disc lit evenly to its
// edge is a coin; a presence has to recede where it turns away, so everything
// is dimmed by a power of z. The exponent is 0.62 rather than 1: a true
// Lambert falloff is too dark too early and eats the material at the rim where
// several of these species keep their best structure.
struct MIOrb {
    float  r;      // 0 at the centre, 1 at the limb
    float  z;      // the ball's height: 1 at the centre, 0 at the limb
    float3 p;      // the point on the unit sphere, which is also its normal
    float  m;      // soft coverage: the silhouette, never a hard edge
    float  limb;   // depth dimming toward the rim
};

static MIOrb mi_orb(float2 uv, float R) {
    MIOrb o;
    float2 q = uv / max(R, 1e-4);
    float d2 = dot(q, q);
    o.r = sqrt(d2);
    o.z = sqrt(max(1.0 - min(d2, 1.0), 0.0));
    // Normalised rather than assembled, so the coordinate continues smoothly
    // past the limb instead of collapsing to zero length in the fade.
    o.p = normalize(float3(q, o.z + 1e-5));
    o.m = 1.0 - smoothstep(0.90, 1.04, o.r);
    o.limb = 0.30 + 0.70 * pow(o.z, 0.62);
    return o;
}

/// Turn the globe about its vertical axis. Material carried on the sphere point
/// then travels around the presence and over its own limb, which is the one
/// motion that says "ball" and not "disc with a picture on it".
static inline float3 mi_spin(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

/// The house orb radius. Big enough to be the whole composition, small enough
/// that its rim and any corona clear the shore.
static inline float mi_orb_radius(float S) { return 0.355 * S; }

// MARK: The flourish clock
//
// Every species in this pack performs ONE gesture: something the material does
// occasionally and then lets go of. This is the clock they all share, and the
// three properties it has are the three the gestures needed.
//
// APERIODIC, AND STILL DETERMINISTIC. Time is cut into slots of P = 6.5 s and
// each slot holds exactly one occurrence, starting at a hashed offset inside a
// window of B = 2.5 s. The interval between two occurrences is therefore
// P + (h_next - h_prev) * B, which lands anywhere in [P - B, P + B] = 4 to 9
// seconds and never twice the same. Nothing accumulates and nothing is
// remembered: sample any t at all, from a screenshot rig or a scrubbed slider,
// and the same occurrence is in the same place. A metronome would have been one
// line shorter and the eye finds a metronome in about three repetitions.
//
// The arithmetic guarantees the slots never collide: the latest an occurrence
// can start is B, and the longest any of them lasts is 2.5 s, so the last one
// ends by 5.0 s inside a 6.5 s slot. That is why only the current slot is ever
// tested, and why `dur` must stay at or under 2.5.
//
// FLAT AT BOTH ENDS. The envelope is a smoothstep up and a smoothstep down, so
// its derivative is zero where it leaves rest and zero where it returns. The
// material never snaps into a gesture or out of one. `rise` sits well under
// half, because a flourish that takes as long to arrive as to relax reads as a
// throb; quick out and slow back is what a gesture is.
//
// AND ZERO IS EXACTLY ZERO. Every gesture in this file is multiplied by the
// envelope, so between occurrences each species is the material that was
// approved, to the bit. The play is added on top of the resting state, never
// mixed into it.
//
// The clock rides each species' own `t`, which already carries the speed dial,
// so the 4-to-9 seconds is a statement about the designed tempo of 1.0.
struct MIBeat {
    float e;    // 0 at rest, 1 at the top of the gesture
    float k;    // 0 to 1 through the gesture, for anything that travels
    float id;   // this occurrence's own number, so no two are aimed alike
};

static MIBeat mi_beat(float t, float lane, float dur, float rise) {
    const float P = 6.5;
    const float B = 2.5;
    float slot = floor(t / P);
    float start = slot * P + mi_hash1(slot, lane) * B;
    float k = (t - start) / max(dur, 1e-3);
    MIBeat g;
    g.id = mi_hash1(slot, lane + 101.0);
    g.k = clamp(k, 0.0, 1.0);
    float up = smoothstep(0.0, 1.0, clamp(k / max(rise, 1e-3), 0.0, 1.0));
    float dn = 1.0 - smoothstep(0.0, 1.0, clamp((k - rise) / max(1.0 - rise, 1e-3), 0.0, 1.0));
    g.e = up * dn;   // both clamps read zero outside the gesture, so rest is exact
    return g;
}

// MARK: The states
//
// Two of the five states are expressed in the shader; the other three are
// carried entirely by their parameter sets, which is the right division of
// labour because a dial set can say "dim and near-still" perfectly well and
// cannot say "an arrival travelled through this material".
//
// SUCCESS, in ink, is a BLOOM OF SATURATION. The one thing this family must
// not do is lay white over the top: paper does not get whiter when the answer
// lands, ink gets DEEPER. So the surge walks the existing field further up the
// rail, from deep amber toward the tone, where there is more chroma and more
// light and it is still the same hue. That is what "the ink drinks" means
// literally: the mark takes up more pigment and holds it.
//
// It travels, and travelling is what makes it an arrival rather than a fade.
// Each species hands mi_drink its own progress coordinate q, so the surge
// sweeps root to tip up the wick, centre to rim across the pool, fold after
// fold along the marbling's lay. The front covers q in 0.7 s and the crest is
// wide enough (0.27 of q) that a small indicator sees a wash rather than a
// scanline. What it leaves behind does not go away: `held` settles at 0.42 and
// stays while the state holds, which is the "settling rich" half of the brief.
//
// RESPONDING is decisive drive, and it is the harder of the two to do honestly
// in a shader with no memory. The obvious implementation, speeding the clock
// up, accumulates: leave the state after twenty seconds and the material jumps
// back by twenty seconds' worth of extra travel. So the drive is built out of
// three things that are all bounded:
//
//   lean    a directional advance that SATURATES, 1 - e^(-tau/0.5), so it
//           arrives over about a second and a half and then holds. Worst case
//           on leaving the state is one bounded nudge, not an unbounded jump.
//   drive   a 0-to-1 ramp for anything that changes AMPLITUDE or COHERENCE:
//           wider wander, tighter forms, sharper alignment. None of it
//           accumulates, so none of it can jump.
//   neither one touches brightness. "Answering now" is posture and motion.
//
// Both ramps are smoothstep or exponential from zero, so entering a state
// never snaps. Leaving one is the Swift layer's problem and it crossfades the
// whole parameter set over 0.6 s to cover it.
struct MIState {
    float success;   // 1 while the state is success
    float sTau;      // seconds since the state was entered
    float drive;     // 0 to 1, responding, eased in over 0.45 s
    float lean;      // 0 to 1, responding, saturating: a bounded advance
};

static MIState mi_state(float stateIndex, float stateTau) {
    MIState s;
    float tau = max(stateTau, 0.0);
    int idx = int(stateIndex + 0.5);
    s.sTau = tau;
    s.success = (idx == 3) ? 1.0 : 0.0;
    float resp = (idx == 2) ? 1.0 : 0.0;
    s.drive = resp * smoothstep(0.0, 0.45, tau);
    s.lean = resp * (1.0 - exp(-tau / 0.50));
    return s;
}

/// The surge, at one point, given where that point sits in the species' own
/// progress coordinate. Returns 0 outside the success state, so every call site
/// is `tv += mi_drink(...) * <how much ink is already here>` and paper that had
/// nothing on it still has nothing on it.
static inline float mi_drink(MIState st, float q) {
    if (st.success < 0.5) { return 0.0; }
    float d = st.sTau * (1.0 / 0.70) - clamp(q, 0.0, 1.0);
    float crest = exp(-(d * d) / 0.075);      // the front passing
    float held = smoothstep(0.0, 0.35, d);    // what it leaves behind
    // A tenth of a second of rise so the flash begins rather than appears.
    return smoothstep(0.0, 0.09, st.sTau) * (crest + 0.42 * held);
}

/// The last three steps, shared, in the order the pour does them.
///
/// `glow` is an exposure on the LIGHT and not on the picture: the ground is
/// held at ink and only what the field put above it is scaled, so turning the
/// dial down dissolves the material into its own ground instead of fading the
/// whole indicator toward grey. Then the shore, then the same soft knee the
/// curtain puts on its surface colour at 0.90 so a hot tone's peaks compress
/// instead of clipping into bands, then the dither, always last, alpha 1.
static inline half4 mi_finish(float3 field, float3 inkLin, float shore,
                              float glow, float2 pixel) {
    float3 lit = inkLin + (field - inkLin) * max(glow, 0.0);
    float3 rgb = mix(inkLin, lit, clamp(shore, 0.0, 1.0));
    rgb = float3(mi_knee(rgb.r, 0.90), mi_knee(rgb.g, 0.90), mi_knee(rgb.b, 0.90));
    return mi_out(rgb, pixel);
}

// MARK: - 1. Bloom

// BLOOM. A drop of ink meeting wet paper.
//
// THE ARC, and it is the whole species. A blot does not spread forever and it
// does not spread at a constant rate: it spreads until the ink it was given is
// spent. The conserved quantity is AREA, not radius, so the law is stated on
// area and the radius is read off it:
//
//   Ȧ = (A∞ - A) / T     the rate falls with what is left to give
//   A(τ) = A∞ (1 - e^(-τ/T))
//   R(τ) = R∞ sqrt(1 - e^(-τ/T))
//
// which is the closed form, not an integration: sample it at any τ at all and
// it lands exactly where the animation would have been. The sqrt is the part
// you can see. It puts almost all of the travel in the first second, the way
// ink actually leaves a nib, and then the front creeps for a long time before
// it arrives. T is 1.25 s, and it is still a statement in real seconds rather
// than a normalised unit: the blot is three quarters of the way out in under a
// second and at the lab's four-second still frame it is at 98% of final, which
// reads as arrived without reading as stopped.
//
// AND WHY IT IS STILL ALIVE AT REST. Nothing about a settled blot is static.
// Two things keep running after the front has stopped, both of them free:
// the fringe noise moves through its third coordinate, so the fingers grow and
// retract in place; and the interior texture is read at a radius pulled back by
// the distance the front has already travelled, which means the mottling keeps
// creeping outward forever at a vanishing rate. Arrived, still moving. That is
// what ink on paper does and it is the opposite of a frozen frame.
//
// THE FRINGE has no seam because it is not an angular function. It is a 3D
// field read on a RING: sample the unit circle inside the noise and the result
// is periodic in theta by construction, so there is no join at the back of the
// blot to hide.
//
// THE GRAIN. Paper is anisotropic; ink runs further along the fibre than
// across it, and the drop never lands dead centre. Both of those are the same
// knob, because they are the same fact about the sheet.
//
//   c0 spread     R∞, how far the front gets before the ink runs out
//   c1 edgeTear   the amplitude and pitch of the fringe: a clean meniscus at 0,
//                 fingering at 1
//   c2 tail       the dilute wash that runs ahead of the saturated front
//   c3 asymmetry  the grain of the sheet: the ellipse, the lobe, the offset
[[ stitchable ]] half4 mi_bloom(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float spread = clamp(c0, 0.0, 1.0);
    float tearK  = clamp(c1, 0.0, 1.0);
    float tailK  = clamp(c2, 0.0, 1.0);
    float asym   = clamp(c3, 0.0, 1.0);

    MIState st = mi_state(stateIndex, stateTau);
    float tau = max(time - epoch, 0.0) * max(speed, 0.0);

    // THE ORB. Ink blooming inside a glassy ball. The physics is untouched: the
    // area law, the live fringe, the tide line that carries the cream. What
    // changed is the space it happens in. The front used to be a circle in a
    // flat frame; it is now a ball of ink expanding from a seed INSIDE the
    // sphere, and what the pixel sees is where that ball cuts the surface, so
    // the ring the front draws is foreshortened by the curvature and reads as
    // something happening within a volume rather than on a card.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    // The law, unchanged. Area, not radius, is what a blot conserves; the
    // distance it is measured against is simply three-dimensional now.
    const float T = 1.25;
    float k = exp(-tau / T);                      // 1 at the drop, 0 arrived
    float Rinf = (0.62 + 0.55 * spread) * (1.0 + 0.13 * st.lean);
    float R = Rinf * sqrt(max(1.0 - k, 0.0));

    // Where the drop went in. Off centre and off axis, so the bloom is a thing
    // happening at a place in the ball rather than a concentric target.
    const float3 GRAIN = float3(0.7071, -0.4243, 0.5657);
    float3 seed = GRAIN * (0.16 + 0.26 * asym);
    float3 sp = mi_spin(o.p, tau * 0.045);        // the ball turns, slowly
    float3 fromSeed = sp - seed;
    float dseed = length(fromSeed);
    float3 dirS = dseed > 1e-5 ? fromSeed / dseed : float3(1.0, 0.0, 0.0);

    // Paper is anisotropic and so is this: the ink runs further along the grain
    // than across it, which on a ball means the front is an ellipsoid.
    float along = dot(dirS, GRAIN);
    float aniso = 1.0 + asym * (0.24 * along * along + 0.11 * along);

    // The live edge, sampled on the SPHERE OF DIRECTIONS from the seed, so it
    // is periodic in every direction at once with no seam and no pole.
    float ring = 1.6 + 1.9 * tearK;
    float fringe = mi_fbm3(dirS * ring + float3(0.0, 0.0, tau * 0.32), 2, 2.03, 0.5);

    // THE FLOURISH: a lobe runs, now a solid angle rather than a sector.
    MIBeat gb = mi_beat(tau, 3.0, 2.2, 0.30);
    float ga = gb.id * 6.2831853;
    float3 gd = normalize(float3(cos(ga), sin(ga) * 0.7, 0.55));
    float lobe = pow(max(dot(dirS, gd), 0.0), 3.0);

    float Rf = R * aniso * (1.0 + (0.10 + 0.42 * tearK) * (1.0 + 0.45 * st.drive) * fringe)
                         * (1.0 + gb.e * 0.17 * lobe);

    float sd = Rf - dseed;                         // > 0 inside the front
    float w = 0.045 + 0.075 * Rinf;
    float core = smoothstep(-w, w, sd);
    float lt = 0.030 + 0.100 * tailK;
    float wash = exp(-max(-sd, 0.0) / lt) * (1.0 - core);
    float wr = 0.048 + 0.070 * Rinf;
    float tide = exp(-(sd * sd) / (wr * wr));

    // The interior keeps creeping after the front has stopped: the texture is
    // dilated as the ball of ink grows, so it expands forever at a vanishing
    // rate rather than sliding through the material.
    float mott = mi_fbm3(sp * (4.2 / (1.0 + 0.62 * R)) + float3(0.0, 0.0, tau * 0.070 + 12.0),
                         3, 2.03, 0.5);

    float dens = core * (0.62 + 0.26 * mott) + 0.45 * wash;
    // The glassy ball: everything recedes toward the limb, and the ink that is
    // deeper in the sphere shows through dimmer than the ink at the front of it.
    float body = clamp(dens, 0.0, 1.2) * o.limb;
    float tv = 0.045 + 0.70 * body + (0.54 + 0.14 * tearK) * tide * o.limb;
    tv += mi_drink(st, saturate(dseed / max(Rf, 1e-4))) * body * 0.26;
    tv *= o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 2. Marbling

/// THE RAKE, and it is the whole of marbling. A marbler does not warp the bath;
/// they draw a comb through it, and every tine displaces the ink ALONG the
/// comb's travel by an amount that varies ACROSS it. Written as a field that is
/// a shear: the displacement is perpendicular to the direction it varies in, so
/// its divergence is exactly zero. Area preserving. That is why raked ink
/// stretches into cusps and never thins into a fog: the comb moves the ink, it
/// does not make more or less of it. A domain warp with a noise offset, which is
/// what the first cut of this shader did, is not area preserving and it looked
/// like smoke.
///
/// On the globe the same operator runs between two orthogonal axes of the
/// sphere and the result is renormalised back onto the surface, so the comb is
/// drawn THROUGH the ball rather than across a picture of it: the folds bend
/// with the curvature and carry over the limb by themselves.
static inline float3 mi_rake3(float3 p, float3 axis, float3 across,
                              float freq, float amp, float phase) {
    return normalize(p + across * (amp * sin(dot(p, axis) * freq + phase)));
}

// MARBLING. A combed sheet. Suminagashi tempo: slow, and never twice the same.
//
// THREE RAKES, at three angles, three pitches and three amplitudes that halve
// down the stack, which is the same reason fBm halves: the first pass makes the
// gesture, the later ones make it look handmade. The middle rake runs its phase
// BACKWARDS. That is the whole motion of this style: two combs turning against
// each other, so the laminae slide past one another instead of the sheet
// travelling. Nothing here falls, nothing pulses, and there is no loop point:
// the three phase rates (0.57, 0.41, 0.31 rad/s) are incommensurate, so the
// pattern never repeats and the eye never finds the cycle. The slowest of them
// comes round in about twenty seconds and the fastest in eleven, which is a
// comb being drawn at a working pace rather than a tide going out.
//
// THE LAMINAE, and the honest problem with them. Marbled ink reads as thin
// concentrated veins, and a thin vein is exactly the thing a 20 pt indicator
// cannot draw: below a pixel a line is not a line, it is aliasing. So the bands
// band-limit themselves. The cosine is multiplied by exp(-(pi w)^2 / 2), which
// is a smooth stand-in for the sinc envelope a box filter of one pixel actually
// applies, so as the bands close toward the sample spacing their contrast falls
// to zero instead of turning into moire; and what is left when they are gone is
// not a flat grey but the SHEET itself, the broad fBm the bands were drawn on.
// Small: a folded soft mass, one clear gesture. Large: the same mass with the
// veins visible in it. The same trick and the same reasoning as the Contour
// field's isolines, which is where it is copied from.
//
//   c0 folds      how many laminae the sheet carries
//   c1 comb       how hard the rakes are drawn through it
//   c2 contrast   vein against ground: a wash at 0, drawn ink at 1
//   c3 drift      the bulk slide of the whole sheet through the frame
[[ stitchable ]] half4 mi_marbling(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float folds    = clamp(c0, 0.0, 1.0);
    float comb     = clamp(c1, 0.0, 1.0);
    float contrast = clamp(c2, 0.0, 1.0);
    float driftK   = clamp(c3, 0.0, 1.0);

    MIState st = mi_state(stateIndex, stateTau);

    // THE ORB. Marbled ink wrapping a ball. One dominant comb, drawn through
    // the sphere rather than across a plane, so the folds curve with the
    // surface and run over the limb.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    // The bath turns under the comb, which is what carries a fold out of sight
    // on one side while another arrives on the other.
    float3 sp = mi_spin(o.p, t * 0.075 + driftK * t * 0.10);

    // RESPONDING: the comb commits. The bath leans along the lay and the rake
    // is drawn deeper, so the sheet folds decisively in ONE direction rather
    // than merely folding harder everywhere.
    const float3 LAY = float3(0.2588, 0.9659, 0.0);
    const float3 AX1 = float3(0.9563, 0.2924, 0.0);
    const float3 AX2 = float3(0.0, 0.4067, 0.9135);
    sp = normalize(sp - LAY * (st.lean * 0.075));

    float A = 0.085 + 0.130 * comb;
    sp = mi_rake3(sp, AX1, LAY, 3.1, A * (1.0 + 0.55 * st.drive), t * 0.57);
    sp = mi_rake3(sp, LAY, AX2, 5.3, A * 0.28, -t * 0.41 + 1.7);

    // THE FLOURISH: a fourth comb stroke, the marbler picking the comb up and
    // drawing it through once more at a new angle before setting it down.
    MIBeat gm = mi_beat(t, 11.0, 2.4, 0.28);
    float gAng = gm.id * 3.1415927;
    float3 gAx = normalize(float3(cos(gAng), sin(gAng), 0.45));
    float3 gAc = normalize(cross(gAx, float3(0.0, 0.0, 1.0)));
    sp = mi_rake3(sp, gAx, gAc, 4.2, (0.090 + 0.070 * comb) * gm.e,
                  t * 0.44 + gm.id * 6.2831853);

    // The sheet of ink the comb is drawn through, painted on the ball.
    float sheet = mi_fbm3(sp * 1.55 + float3(0.0, 0.0, t * 0.046 + 21.0), 3, 2.03, 0.5);

    float count = 0.90 + 1.50 * folds;
    float u = (sheet * 2.1 + dot(sp, LAY) * 1.35) * count;

    float wpx = max(fwidth(u), 1e-5);                  // cycles per device pixel
    float att = exp(-4.9348 * wpx * wpx);              // exp(-(pi w)^2 / 2)
    float sc = 0.5 + 0.5 * cos(6.2831853 * u) * att;
    float body = pow(sc, 1.0 + 2.4 * contrast);

    // The vein is a ribbon and not a hairline: its width is a fraction of the
    // BAND, with a pixel floor under it so it survives at 20 pt.
    float dc = abs(fract(u + 0.5) - 0.5);
    float halfW = max(0.145, 1.8 * wpx);
    float vein = exp(-(dc * dc) / (halfW * halfW)) * att;

    float mass = (0.20 + 0.80 * mix(saturate(0.5 + 0.85 * sheet), body, att)) * o.limb;
    float tv = 0.055 + 0.62 * mass + (0.32 + 0.14 * contrast) * vein * o.limb;
    tv += mi_drink(st, saturate(0.5 + dot(sp, LAY) * 0.7)) * (mass + 0.6 * vein) * 0.26;
    tv *= o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 3. Wick

// WICK. Ink climbing fibre. Gravity in reverse, and the paper visible in it.
//
// WHY THERE IS NO ARC HERE even though capillary rise obviously has one. The
// climb of a wetting front goes as sqrt(t), Washburn, and it would make a
// lovely arrival; but a wick is a STATE, not an event, and a style that arrives
// once and then holds is already in this pack twice. So this one is written at
// the equilibrium instead, which is the other half of the same physics and the
// half nobody draws: Jurin's law, where every pore climbs to the height its own
// radius can hold and stops. Fine fibre high, coarse fibre low, and the wet
// line is therefore RAGGED by construction rather than by decoration.
//
// The front is a slice of the 3D field taken along x with time in z, so the
// height at a given place changes IN PLACE. That matters more than it sounds.
// The obvious implementation moves the noise sideways, and a wet line that
// travels sideways is a conveyor belt; a wet line that rises and stalls where
// it stands is stick-slip in a porous medium, which is the thing capillary
// fronts actually do.
//
// WHAT MOVES, since the front does not. The grain inside the wet region is read
// at a y pulled DOWNWARD by time, so the fibre texture creeps up through the
// standing front at six hundredths of a frame a second. The front has
// arrived; the ink has not stopped. That is the whole feeling of a wick and it
// is one term.
//
// AND THE TIDE LINE. Where the front stalls, solvent keeps leaving and pigment
// does not, so the edge of a chromatogram is always the darkest part of it.
// Same gaussian as the bloom's, same reason, and it is what makes the ragged
// line legible at 20 pt: the gesture is an edge, not a mass.
//
//   c0 climb      the mean height the pores can hold
//   c1 fiber      the tooth of the sheet: how ragged the line, how visible the
//                 grain in the climb
//   c2 pooling    the reservoir at the foot, where the sheet stands in ink
//   c3 dryEdge    how sharply the wet meets the dry, and how hard the tide line
//                 concentrates on it
[[ stitchable ]] half4 mi_wick(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    // Up is +y here and nowhere else in this file. This style is ABOUT the
    // direction, so it gets to own the sign.
    MIState st = mi_state(stateIndex, stateTau);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float climb   = clamp(c0, 0.0, 1.0);
    float fiber   = clamp(c1, 0.0, 1.0);
    float pooling = clamp(c2, 0.0, 1.0);
    float dry     = clamp(c3, 0.0, 1.0);

    // THE ORB. The saturation front climbs THROUGH a spherical body: root at
    // the south pole, crown at the north, and the wetted line is a parallel of
    // latitude, so the curvature bends it into the arc a band on a ball makes.
    // The physics is the one it always was, Jurin's equilibrium with a ragged
    // front, read in latitude instead of in height.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));
    float3 sp = o.p;
    float lat = -sp.y;                             // -1 at the foot, +1 at the crown

    // The longitude, as a seam-free unit vector rather than an angle. An atan2
    // here would put a cut down the back of the presence where the noise wraps,
    // and on a turning globe that cut walks around into view.
    float3 lon = normalize(float3(sp.x, 0.0, sp.z + 1e-5));

    float h0 = -0.42 + 0.92 * climb;
    float rag = mi_fbm3(float3(lon.x, lon.z, t * 0.175 + 4.0) * (2.6 + 1.4 * fiber),
                        3, 2.03, 0.5);
    float front = h0 + (0.10 + 0.20 * fiber) * rag;

    // THE FLOURISH: one thread runs ahead, a single fibre carrying ink past
    // where the rest of the front has stalled, now a meridian on the globe.
    MIBeat gw = mi_beat(t, 23.0, 2.0, 0.26);
    float gAng = gw.id * 6.2831853;
    float dxg = (dot(lon, float3(cos(gAng), 0.0, sin(gAng))) - 1.0) / 0.10;
    front += gw.e * (0.34 + 0.20 * climb) * exp(-dxg * dxg);

    // RESPONDING: the ink pushes further up the body.
    front += st.lean * 0.17;

    float sd = front - lat;                        // > 0 wet
    float wEdge = 0.060 - 0.036 * dry;
    float wet = smoothstep(-wEdge, wEdge, sd);

    // The tooth of the sheet, wrapped: high frequency around the globe, low
    // along the climb, so the striation runs up the body and over the crown.
    // The latitude term carries the transport.
    float3 gp = float3(lon.x, lon.z, 0.0) * (7.0 + 3.0 * fiber)
              + float3(0.0, 0.0, (lat + t * 0.085) * 2.2);
    float grain = mi_fbm3(gp, 2, 2.03, 0.55);

    float conc = mix(0.52, 1.0, saturate(sd / 0.85));
    float wr = 0.048 + 0.060 * (1.0 - dry);
    float tide = exp(-(sd * sd) / (wr * wr));
    float src = 1.0 - smoothstep(-0.95, -0.30, lat);

    float dens = wet * conc * (0.80 + 0.85 * fiber * grain) + pooling * 0.42 * src;
    float tv = 0.045 + 0.64 * clamp(dens, 0.0, 1.3) * o.limb
             + (0.70 + 0.20 * dry) * tide * o.limb
             // THE DRY HEMISPHERE IS STILL THE PRESENCE. On the flat version
             // this was a whisper of tooth above the wet line and that was
             // right, because the ground there was paper. On a ball the ground
             // above the line is the BODY, and leaving it near ink cut the orb
             // in half: the silhouette stopped closing and the species went
             // back to reading as a vessel with something in it. The dry part
             // now carries a real amber, dimmer than the wetted part by a
             // factor of three, which is what a sphere looks like when only
             // some of it has drunk.
             + (0.15 + 0.10 * (0.5 + 0.5 * grain)) * (1.0 - wet) * o.limb;
    tv += mi_drink(st, saturate((lat + 1.0) / max(front + 1.0, 1e-3)))
        * wet * conc * 0.26;
    tv *= o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 4. Strata

// STRATA. Sediment finding its level.
//
// THE ARC, and it is the cleanest one in the pack because the physics writes
// it. A suspension settles at a rate set by how much is still up there, which
// is a first-order relaxation and has an exact solution rather than an
// integral to accumulate:
//
//   ḣ = -(h - h∞) / T    →    h(τ) = h∞ + (h0 - h∞) e^(-τ/T)
//
// so one exponential, k = e^(-τ/T), carries the entire arrival: 1 is turbid,
// 0 is settled, and any τ at all lands where the animation would have been.
//
// HOW A CLOUD BECOMES LAYERS without drawing a single layer. One fBm, read
// through an ANISOTROPY that k controls. Suspended, the domain is scaled the
// same in both axes and the field is an isotropic turbidity. Settled, the
// horizontal frequency has dropped and the vertical has climbed, so the level
// sets of that same field are stretched flat and ARE the laminae: irregular,
// varying in thickness, never a comb, because they were never drawn as one.
// Two octaves only. Lamination wants smooth bands; a third octave puts detail
// inside a band that no size in the roster can resolve.
//
// And the bed builds while the water clears: the density envelope goes from
// uniform turbidity to dense-below, hazy-above. The supernatant never reaches
// zero (0.16) because it does not in a jar either. The fines stay up for hours.
//
// ALIVE AT REST. A settled bed does not un-settle. The vessel it settled in is
// never perfectly level, though, so the whole bed carries a slow rock, two
// incommensurate sines about half a degree each, and the disturb knob leaves a
// residual convection rippling the boundaries. Neither of those is a pulse and
// neither ever stops.
//
//   c0 layers     the vertical frequency at rest: how many beds
//   c1 settle     how quickly the suspension arrives (T, 1.6 s at the default,
//                 and still a count of real seconds rather than a normalised
//                 unit: three time constants is under five seconds)
//   c2 disturb    residual convection in the boundaries
//   c3 tilt       which way the vessel leans, 0.5 being level
[[ stitchable ]] half4 mi_strata(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float layers  = clamp(c0, 0.0, 1.0);
    float settle  = clamp(c1, 0.0, 1.0);
    float disturb = clamp(c2, 0.0, 1.0);
    float tiltK   = clamp(c3, 0.0, 1.0);

    MIState st = mi_state(stateIndex, stateTau);
    float tau = max(time - epoch, 0.0) * max(speed, 0.0);
    float T = 1.6 / (0.55 + 0.90 * settle);
    float k = exp(-tau / T);                       // 1 suspended, 0 settled
    float clear = 1.0 - k;

    // THE ORB. A geode: the sediment settles INSIDE the sphere. Courses are
    // parallels of latitude, so the curvature bends every one of them into the
    // arc a band on a ball makes, and the top surface is a curved cream line
    // across the presence rather than a horizon across a scene.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    // The vessel's lean, and the rock it never quite loses. On a ball the lean
    // is a tilt of the settling axis, so the whole stack tips together.
    float rock = 1.0 - 0.55 * st.drive;
    float ang = (tiltK - 0.5) * 0.40
              + rock * (0.035 * sin(t * 0.31) + 0.022 * sin(t * 0.19 + 2.1));
    float ca = cos(ang), sa = sin(ang);
    float3 sp = o.p;
    float lat = -(sp.y * ca - sp.x * sa);          // up the tilted axis
    float across = sp.x * ca + sp.y * sa;

    float rip = mi_fbm3(sp * 2.2 + float3(0.0, 0.0, t * 0.128 + 31.0), 2, 2.03, 0.5);
    float y = lat + disturb * 0.085 * rip;

    // The heap, and the arc that builds it. Turbid, the surface sits near the
    // crown and is soft enough to be no surface at all, which is a cloud
    // filling the whole ball; settled, it drops to a low mound with a crisp top
    // and the courses separate under it.
    float mound = exp(-(across * across) / 0.55);
    float wob = mi_noise3(float3(sp.x, sp.z, tau * 0.05 + 51.0) * 2.4);

    MIBeat gs = mi_beat(t, 37.0, 2.4, 0.34);
    float xg = (gs.id * 2.0 - 1.0) * 0.55;
    float dxs = (across - xg) / 0.30;
    float lens = gs.e * 0.10 * exp(-dxs * dxs);

    float surfY = mix(0.92, -0.06 + 0.26 * mound + 0.07 * wob, clear)
                + lens - 0.07 * st.drive;
    float below = surfY - y;                       // > 0 inside the bed
    float ws = mix(0.55, 0.045, clear);
    float inBed = smoothstep(-ws, ws, below);

    // The courses, measured DOWN FROM THE SURFACE so they lie parallel to it
    // and move with it, band-limited by fwidth so at 20 pt they dissolve into
    // the mass rather than aliasing.
    float bandN = (2.6 + 2.4 * layers) / 0.90 * (1.0 + 0.22 * st.drive);
    float nz = mi_fbm3(float3(across * 1.6, y * 1.5, tau * 0.045 + 3.0), 2, 2.03, 0.5);
    float bp = below * bandN + 0.42 * nz;
    float wpx = max(fwidth(bp), 1e-5);
    float att = exp(-4.9348 * wpx * wpx);
    float band = 0.5 + 0.5 * cos(6.2831853 * bp) * att;
    band = mix(0.5, pow(band, 1.0 + 1.6 * layers), clear);

    float comp = 1.0 + 0.45 * saturate(below / 0.80);
    float dens = inBed * (0.40 + 0.60 * band) * comp * (0.72 + 0.28 * (0.5 + 0.8 * nz));
    float haze = (1.0 - inBed) * (0.30 + 0.70 * k) * saturate(0.5 + 0.9 * nz);

    // The surface line: the only thing in this presence that reaches the rail's
    // pale stop, and it arrives with the settling because before there is a bed
    // there is nothing for a surface to be.
    float line = exp(-(below * below) / (0.060 * 0.060)) * clear;

    // The supernatant is not empty space, it is the rest of the geode, so it
    // carries a body of its own. Left near ink it cut the sphere in half and
    // the presence read as a bowl with sediment in it, which is a scene.
    float tv = (0.045 + 0.52 * clamp(dens, 0.0, 1.4) * o.limb
             + (0.17 + 0.16 * haze) * (1.0 - inBed) * o.limb
             + 0.10 * haze * o.limb + 0.72 * line * o.limb) * o.m;
    tv += mi_drink(st, 1.0 - saturate(below / 0.90)) * clamp(dens, 0.0, 1.4) * 0.26 * o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 5. Halation

// HALATION. A dark mass wearing its own light.
//
// The name is photographic and so is the effect: on a dense negative, light
// that got through the emulsion scatters off the backing and comes back out
// AROUND the dense area, so the darkest thing in the frame is the thing wearing
// the glow. Nothing else in this pack is lit that way. Every other style here
// is bright where the material is; this one is dark where the material is and
// bright at its shoulder.
//
// THE LOAD-BEARING TRICK, and it is the only reason this style is affordable.
// A halo of even width around an irregular silhouette normally costs a blur:
// eight or twelve taps of the mass field to find how far away the boundary is.
// It costs one tap here, because the fBm carries its own analytic gradient, and
// a first-order signed distance to the level set is
//
//   d = (f - threshold) / |grad f|
//
// in the SAME units as the frame once the gradient is carried back through the
// domain scale by the chain rule. That division is the whole point. Without it
// the halo is thick wherever the field is flat and a hairline wherever it is
// steep, which does not read as light at all: it reads as a printing fault. One
// mi_fbmd3 at three octaves buys the mass, its silhouette, the halo width, the
// rim and the direction the light falls from, and nothing else in this file is
// cheaper.
//
// THE OFFSET is which way the scatter goes. The halo is weighted by how much
// the boundary's outward normal faces the light, so the mass is not ringed
// evenly: one shoulder carries the glow and the other keeps its dark. A
// symmetric halo around a blob is a sticker; an asymmetric one is a body in a
// room with a light in it.
//
// The mass reforms and also DRIFTS, about two hundredths of a frame a second.
// A mass that only morphs in place reads as a lava lamp on a timer.
//
//   c0 mass       the threshold: how much of the frame the dark body occupies
//   c1 corona     the width and strength of the scatter
//   c2 morph      how fast the body reforms
//   c3 offset     the direction the light comes from, in turns
[[ stitchable ]] half4 mi_halation(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    MIState st = mi_state(stateIndex, stateTau);
    float massK  = clamp(c0, 0.0, 1.0);
    float corona = clamp(c1, 0.0, 1.0);
    float morph  = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // THE ORB, and this species was already most of the way there: a dark mass
    // wearing its own light. What the orb law sharpens is the SPHERICAL read.
    // The body's well is now the ball itself, so the silhouette is a sphere
    // that the noise lobes rather than a blob that happens to be roundish, the
    // interior is dimmed toward the limb so it reads as a body with a far side,
    // and the corona is the light coming off a globe rather than off a cutout.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    // The field is carried ON the ball and the ball turns, so lobes swell on
    // one shoulder, ride around and are absorbed on the other. A field evolving
    // only in its own third coordinate has no direction and reads as flicker;
    // this reads as a mass reforming.
    float spin = t * (0.075 + 0.14 * morph);
    float3 sp = mi_spin(o.p, spin);

    // THE FLOURISH: the mass leans and returns, its centre of gravity sliding
    // off the axis and coming back while the noise it is cut from stays put.
    MIBeat gh = mi_beat(t, 53.0, 2.3, 0.32);
    float gha = gh.id * 6.2831853;
    float2 off = float2(cos(gha), sin(gha)) * (gh.e * 0.052)
               + float2(0.80, -0.60) * (st.lean * 0.045);
    // The body's centre of gravity slides and comes back; measuring the
    // silhouette from the offset centre is what makes the mass LEAN rather
    // than the whole presence translate.
    float2 uvc = uv - off * 1.6;
    float rc = length(uvc) / max(mi_orb_radius(S), 1e-4);

    // THE SILHOUETTE, and this replaces the signed-distance construction that
    // came over from the flat version. That one measured |grad f| to turn a
    // field value into a screen distance, and on a ball the field reaches the
    // screen through a noise domain, then a rotation, then the sphere's own
    // nonlinear projection. The analytic chain rule through all three is three
    // matrices and one silent mistake away from a halo that slides off its
    // mass; hardware derivatives get it exactly right and then quantise it,
    // because dfdx is constant across a 2x2 quad, and a distance quantised at
    // quad resolution and fed to a narrow exponential draws the quad grid.
    // Both were tried and the second one was visible on the rim.
    //
    // The answer is not to measure a distance at all. The body of this species
    // is a lobed ball, so its EDGE can simply be stated: a radius per
    // direction, on the ring of screen directions where the noise wraps by
    // construction. Then the distance to it is exact, smooth, free, and in
    // frame units already. It is the same move the bloom's front makes, and it
    // should have been the first answer here rather than the third.
    float2 dir2 = rc > 1e-4 ? uvc / max(length(uvc), 1e-5) : float2(1.0, 0.0);
    float lobeN = mi_fbm3(float3(dir2 * (1.35 + 0.9 * massK), spin * 0.55 + 6.0),
                          2, 2.03, 0.42);
    // The pedestal guarantees a body at every angle however the noise lands, and
    // the amplitude is what makes it a lobed mass rather than a circle with
    // texture: the radius swings about a third either side.
    float bodyR = (0.74 + 0.16 * massK) / (1.0 + 0.18 * st.drive) * (1.0 + 0.34 * lobeN);
    float d = (bodyR - rc) * mi_orb_radius(S);    // signed, in frame units

    float inside = smoothstep(-0.004, 0.010, d);

    // The outward normal of the silhouette is the screen direction itself, to
    // within the small tilt the lobing adds, which is all the facing term needs.
    float2 nOut = dir2;
    float a = offset * 6.2831853;
    float facing = 0.5 + 0.5 * dot(nOut, float2(cos(a), sin(a)));

    // Halation is a GLOW and not an outline, so the corona is wide and the rim
    // is only its hot core; weighted the other way the mass wears a drawn edge,
    // which is the one thing a scattering effect never looks like.
    float w = 0.022 + 0.100 * corona;
    float halo = exp(-max(-d, 0.0) / w) * (1.0 - inside);
    float wr = 0.020 + 0.024 * corona;
    float rim = exp(-(d * d) / (wr * wr));
    // The body is dark but it is not a hole: it holds the rail's deep shadow at
    // its shoulder and gives even that up toward its middle, and the limb
    // dimming makes the far side of the ball darker than the near.
    // The body is dark but it is not a hole. It holds the rail's deep shadow at
    // its shoulder, gives even that up toward its middle, and carries the
    // turning field inside it so there is something in there and not an absence.
    float grain = mi_fbm3(sp * 2.6 + float3(0.0, 0.0, t * 0.05), 2, 2.03, 0.5);
    float core = 0.26 * exp(-max(d, 0.0) / 0.30) * o.limb
               * (0.70 + 0.42 * (0.5 + 0.5 * grain));

    float tv = 0.040
             + inside * core
             + (0.16 + 0.62 * corona) * halo * (0.35 + 0.65 * facing)
             + (0.36 + 0.24 * corona) * rim  * (0.35 + 0.65 * facing);
    tv += mi_drink(st, saturate(-d / 0.20))
        * (halo + 0.6 * rim + 1.2 * inside * core) * 0.26;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 6. Pool

// POOL. Ink already at rest in a shallow dish. The stillest style in the set.
//
// Every other shader here is about ink going somewhere. This one has arrived,
// and the whole design question was what is left to look at when nothing is
// happening. The answer a real dish of ink gives: the surface is a mirror, and
// a mirror does not need to move to be alive. A tremor a fraction of a degree
// across is invisible as displacement and enormous as REFLECTION, because the
// specular exponent turns a tenth of a degree of slope into a visible swing of
// light. So the tremor knob defaults to 0.2 and the picture still changes all
// afternoon. That asymmetry between how much the surface moves and how much the
// light moves is the entire species.
//
// THE SLOPE IS ANALYTIC. The surface is one mi_fbmd3 and the normal comes off
// its gradient in the same evaluation, which is what the derivative kit is for.
// Finite differences would have cost four more taps to compute a quantity the
// field already knows, and they would have carried the lattice's stairs into
// the highlight where a mirror shows them worst.
//
// THE MENISCUS. Ink climbs the wall of the dish over its capillary length, and
// that climb is a steep curved surface right at the shore, so it catches a line
// of light the flat middle never gets. It is added to the SLOPE and not to the
// brightness, which means the rim highlight obeys the same light as everything
// else: brighter where the wall faces the source, dark where it turns away.
// Painting it as a ring of light instead would have drawn a circle, and a
// circle is the one shape this pack is not allowed to draw.
//
// THE SHORE IS A PUDDLE, not a machined disc. The radius wanders about a
// seventh with a slow angular noise, the dish leans so the ink pools to one
// side, and there is a dried tide of pigment just outside the wet edge where an
// earlier fill retreated. Those three together are what keep this from reading
// as a lit dot, which it must never do.
//
//   c0 tension    the size of the pool and the length of the meniscus climb
//   c1 tremor     surface motion. 0.2 is right; 1.0 is a dish somebody knocked
//   c2 sheen      how tight and how strong the reflected highlight is
//   c3 tilt       which way the dish leans, 0.5 being level
[[ stitchable ]] half4 mi_pool(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    MIState st = mi_state(stateIndex, stateTau);
    float tension = clamp(c0, 0.0, 1.0);
    float tremor  = clamp(c1, 0.0, 1.0);
    float sheenK  = clamp(c2, 0.0, 1.0);
    float tiltK   = clamp(c3, 0.0, 1.0);

    // THE ORB. A liquid ball at rest. Everything this species was about
    // survives the move and most of it gets easier: the surface is now a real
    // surface with a real normal, so the sheen is a genuine reflection off a
    // curved body rather than a highlight painted on a disc, and the meniscus
    // becomes the CROWN, the bright ring of tension where the limb turns away.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    float lean = (tiltK - 0.5) * 2.0;
    float3 low = normalize(float3(0.6428, 0.7660, 0.35)) * lean;

    // The ball turns under its own skin, which is what carries a slack of
    // tension around to the far side.
    float3 sp = mi_spin(o.p, t * 0.026);

    // THE SURFACE. One tap, and its analytic gradient is the perturbation of
    // the normal: this is what the derivative kit is for, and finite
    // differences would have cost four more taps to learn something the field
    // already knows.
    const float SF = 2.4;
    float4 Sf = mi_fbmd3(sp * SF + float3(0.0, 0.0, t * (0.062 + 0.130 * tremor) + 41.0),
                         3, 2.03, 0.5);
    float3 ripple = Sf.yzw * (0.055 + 0.150 * tremor);

    // THE FLOURISH: one ring from an unseen touch, running out from a point on
    // the ball and dying. It is added to the NORMAL and makes no light of its
    // own: a ring painted as brightness is a drawn circle, a ring that tips the
    // surface is caught by the light and arrives as a bright arc.
    MIBeat gp = mi_beat(t, 71.0, 2.4, 0.22);
    float rga = gp.id * 6.2831853;
    float3 touch = normalize(float3(cos(rga) * 0.8, sin(rga) * 0.8, 0.62));
    float rg = length(sp - touch);
    float xr = (rg - gp.k * 1.35) / 0.16;
    float3 tdir = rg > 1e-5 ? (sp - touch) / rg : float3(1.0, 0.0, 0.0);
    ripple += tdir * (2.33 * xr * exp(-xr * xr) * gp.e * 0.16);

    // Surface tension pulls the skin taut while responding.
    float3 nrm = normalize(o.p + ripple * (1.0 - 0.30 * st.drive));

    // The light sits nearly overhead, a little to the upper left. Nearly is
    // load bearing: out at forty degrees a smooth ball returns almost nothing
    // through a high exponent and the presence goes black except where it
    // happens to tip. Overhead, a still surface is quietly lit and the tremor
    // MODULATES that instead of switching it on.
    const float3 LIGHT = normalize(float3(-0.34, -0.46, 0.82));
    float spec = pow(saturate(dot(nrm, LIGHT)), 6.0 + 14.0 * sheenK);

    // The body: warm liquid, deepest through the middle where you are looking
    // through the most of it, leaning to the low side.
    float h = o.limb * (1.0 + 0.28 * dot(o.p, low));

    // THE CROWN. The meniscus, wrapped onto the ball: the ring of tension right
    // at the limb where the surface turns away, and this species' one cream
    // structure. It rides the light too, so it is brighter where the crown
    // faces the source and darker where it turns, which is what keeps it from
    // being a stroked circle.
    // THE CROWN SITS INSIDE THE LIMB, and that correction is the whole of this
    // structure working. Written against o.z it hugged the silhouette exactly,
    // which is precisely where the coverage mask is busy fading the presence
    // out: the ring got multiplied away and the orb came back a flat disc. A
    // ring of tension at four fifths of the radius is fully inside the mask,
    // still reads as the place the surface turns away, and is the one thing
    // here that reaches the rail's cream stop.
    float lambda = 0.055 + 0.045 * tension;
    float dcr = (o.r - (0.80 - 0.05 * st.drive)) / lambda;
    float crown = exp(-dcr * dcr);
    // It rides the light like everything else, so it is an ARC that is brighter
    // where the crown faces the source, not a stroked circle.
    float crownLit = 0.30 + 0.70 * saturate(dot(nrm, LIGHT) + 0.30);

    // Calmed back down after the crown started working. This is still the
    // stillest species in the pack and it is not allowed to be the brightest:
    // the body sits in amber, the sheen is a broad soft reflection, and the
    // only thing that reaches cream is the ring of tension.
    float tv = (0.045
             + 0.26 * h
             + (0.22 + 0.28 * sheenK) * spec
             + (0.52 + 0.18 * tension) * crown * crownLit * o.limb) * o.m;
    tv += mi_drink(st, saturate(o.r)) * (h + 0.7 * crown) * 0.26 * o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 7. Feather

// FEATHER. Ink running along the grain, hair by hair.
//
// WHY THIS IS NOT ANOTHER BLOOM, which is the first thing to answer because the
// two species share a chemistry. A blot on sized paper spreads the same distance
// in every direction and its story is a circle with a tide line. This is what
// happens on paper that is sized badly or not at all: the ink stops obeying the
// drop and starts obeying the SHEET, running along the fibre far and across it
// barely, so what advances is not a front but a comb of hairs, each one a
// channel, with the mass filling in behind them. Bloom is isotropic and its
// silhouette is round. This is anisotropic and its silhouette is a plume with a
// toothed leading edge. Put the two side by side at 76 pt and nothing about them
// rhymes, which was the requirement.
//
// THE ARC IS ALSO A DIFFERENT LAW, and the difference is not decoration. Bloom
// conserves AREA, so its radius carries a square root and nearly all of its
// travel happens in the first moment. Here the plume is channelled: it advances
// at roughly constant width, so the area it has wetted is proportional to the
// LENGTH, and spending a fixed reservoir of ink over that gives
//
//   L̇ = (L∞ - L) / T      →      L(τ) = L∞ + (L0 - L∞) e^(-τ/T)
//
// a plain exponential approach with no root in it. Closed form, so any τ lands
// where the animation would have been. In the eye the two arcs read as two
// different events: the blot lunges and then creeps for a long time, the feather
// sets off at a walk and eases into its stop. T is 1.45 s, a little longer than
// the blot's 1.25, because a bleed has further to go.
//
// REST IS NOT STILL. When L has arrived the hairs keep working: the fringe noise
// runs on through its third coordinate at 0.22, which is the pack's post-tempo
// rate, so the teeth of the comb lengthen and retract against each other without
// the plume as a whole going anywhere. That is capillary shimmer, and it is what
// a saturated feather actually does under a loupe.
//
//   c0 bleed      how far the plume gets before the ink is spent
//   c1 fiber      the pitch of the grain: how many hairs, how deep the comb, how
//                 visible the striation inside the wetted mass
//   c2 direction  the heading, in turns. This is the knob that keeps the species
//                 off bloom's ground, so it is a real axis and not a nudge
//   c3 dryness    how hard the paper fights the ink: a tight terminating edge
//                 and a concentrated tip on dry stock, a soft one on damp
[[ stitchable ]] half4 mi_feather(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    MIState st = mi_state(stateIndex, stateTau);
    float bleed   = clamp(c0, 0.0, 1.0);
    float fiber   = clamp(c1, 0.0, 1.0);
    float dirK    = clamp(c2, 0.0, 1.0);
    float dryness = clamp(c3, 0.0, 1.0);
    float tau = max(time - epoch, 0.0) * max(speed, 0.0);

    // THE ORB. The bleed spreads ACROSS the sphere's surface from a touch
    // point: ink put on a ball and running along its grain. Everything that
    // made this species itself survives, and the sphere does the composing that
    // the flat version had to be argued into: the mark is compact and centred
    // because the ball is, and the plume's reach is wrapped by the curvature
    // instead of flying off into empty frame.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));

    // The grain of the sheet and the touch point, both directions on the ball.
    // The 0.45 offset keeps the default knob off a screen axis, where a plume
    // running dead level reads as a diagram.
    float ang = dirK * 6.2831853 + 0.45;
    // The touch sits near the middle of the visible face, not out toward the
    // limb: a bleed that starts at the edge runs across the presence and reads
    // as something passing through, which is the projectile the flat version
    // had to be argued out of.
    float3 touch = normalize(float3(-cos(ang) * 0.42, -sin(ang) * 0.42, 0.90));
    // THE GRAIN HAS TO BE TANGENT AT THE TOUCH POINT, and the first cut of this
    // was not: it took a direction in the plane and used it straight, so half
    // of "along the grain" was actually pointing into or out of the ball. Every
    // distance downstream was then measuring a mixture of surface travel and
    // depth, which is why the plume came out as a small speckled patch instead
    // of a bleed. Projecting the direction into the tangent plane is one line
    // and it is the difference between a coordinate and a category error.
    float3 gDir = normalize(float3(cos(ang), sin(ang), 0.0));
    float3 grain = normalize(gDir - touch * dot(gDir, touch));
    float3 side = normalize(cross(touch, grain));

    float3 sp = mi_spin(o.p, tau * 0.030);

    // Along the grain and across it, measured from where the ink went on. The
    // geodesic is approximated by the chord, which on a unit sphere is monotone
    // in the true arc and a great deal cheaper than an arccos.
    // Along the fibre and across it, both as TANGENT components. Taking the
    // across-distance as the 3D length of what is left after removing the along
    // part looks equivalent and is not: what is left also contains the radial
    // direction, so the curvature of the ball leaks in as width and the plume
    // strangles itself a third of the way out. Projecting onto the side axis
    // instead measures only travel over the surface, which is what a bleed
    // actually does.
    float3 rel = sp - touch;
    float alo = dot(rel, grain);                   // along the fibre
    float acr = dot(rel, side);                    // across it, on the surface

    // THE LAW, unchanged. A channelled bleed wets area proportional to LENGTH,
    // so spending a fixed reservoir over it gives a plain exponential approach
    // with no root in it: the blot lunges and creeps, the feather sets off at a
    // walk and eases into its stop.
    const float T = 1.45;
    float L0 = 0.10;
    float Linf = (0.58 + 0.44 * bleed) * (1.0 + 0.15 * st.lean);
    float L = Linf + (L0 - Linf) * exp(-tau / T);

    float u = alo + 0.12;                          // 0 just behind the touch
    float uN = saturate(u / max(Linf, 1e-4));

    // THE FLOURISH: the tip bends to a new fibre and back, weighted by uN
    // squared so the root stays pinned where the pen put it and only the reach
    // swings. The curtain's pinned-at-the-crest trick, on a ball.
    MIBeat gf = mi_beat(tau, 5.0, 2.2, 0.30);
    acr -= (gf.id * 2.0 - 1.0) * gf.e * 0.34 * uN * uN;

    float Wref = 0.42 + 0.26 * bleed;

    // THE GRAIN, and it is the form and not a texture on it. Ink feathering has
    // no silhouette: it advances along individual fibres, and what looks like
    // an edge is only where fewer and fewer of them are still carrying
    // anything. One value decides how far this fibre reaches, how far out to
    // the side the plume gets here, and how much ink is at this point at all,
    // which is what makes the boundary fibrous in every direction.
    // High frequency ACROSS the fibres and low along them, so the texture runs
    // with the bleed. Four to one: paper fibre is short, and stretched further
    // the grain becomes channels the length of the mark, which is motion blur.
    float gr = mi_fbm3(side * (acr * (12.0 + 9.0 * fiber)) + grain * (alo * 4.0)
                     + float3(0.0, 0.0, 21.0 + tau * 0.050) + sp * 1.6,
                     2, 2.03, 0.55);
    float fibre = saturate(0.5 + 0.95 * gr);

    // The teardrop: broad at the head, tapering to the tip, sides wandering on
    // the grain because fibre is not a ruler.
    float W = Wref * (1.22 - 0.86 * uN) * (0.72 + 0.56 * fibre);
    float x2 = (acr * acr) / max(W * W, 1e-8);
    float across = exp(-x2 * x2);

    // Each fibre's own reach, falling off to the sides so the mark CLOSES.
    // Cutting the front at a constant distance along the grain makes the
    // boundary a level set of one coordinate: a straight line with teeth on it.
    float lateralFall = exp(-(acr * acr) / max(2.6 * Wref * Wref, 1e-8));
    float reach = L * (0.82 + 0.30 * fibre) * (0.40 + 0.60 * lateralFall);
    float w = 0.10 + 0.16 * Linf;
    float front = smoothstep(-w, w, reach - u);
    float back = smoothstep(-0.22, 0.22, u + 0.18 + 0.10 * fibre);

    float sat = mix(1.0, 0.82, uN);
    float dTip = reach - u;
    float wt = 0.055 + 0.075 * (1.0 - dryness);
    float tip = exp(-(dTip * dTip) / max(wt * wt, 1e-8)) * back;

    // THE SPINE. A feather's rachis: one bright line down the axis, brightest
    // at the head, and the only part of this species that reaches the rail's
    // cream stop. It is what makes the plume read as oriented at 20 pt.
    float ws = 0.30 * Wref;
    float spine = exp(-(acr * acr) / max(ws * ws, 1e-8)) * front * back
                * (0.34 + 0.66 * (1.0 - 0.75 * uN));

    float dens = front * back * across * sat * (0.30 + 0.85 * fibre);
    // THE UNBLED BALL IS STILL THE PRESENCE. Left at ink, the plume hung in an
    // empty cell and read as an object flying through it rather than as ink on
    // a body: the same failure the flat version had, and on a sphere the fix is
    // simply to draw the sphere. The dry part of the surface carries a dim
    // amber with the grain faintly in it, so the orb closes and the bleed is
    // something happening ON it.
    float dry = (0.15 + 0.09 * (0.5 + 0.5 * gr)) * (1.0 - saturate(dens * 1.6));
    float tv = (0.045 + 0.70 * clamp(dens, 0.0, 1.3) * o.limb
             + dry * o.limb
             + (0.46 + 0.10 * bleed) * spine * o.limb
             + (0.13 + 0.15 * dryness) * tip * across * o.limb) * o.m;
    tv += mi_drink(st, uN) * clamp(dens, 0.0, 1.3) * 0.26 * o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}

// MARK: - 8. Palimpsest

// PALIMPSEST. Older writing coming up through the sheet.
//
// A palimpsest is a page that was scraped and written over, and the ghost of
// what it used to say keeps rising back through the new surface. That is the
// species: marks that are almost readable, in rows, that surface somewhere,
// hold for a moment and are taken back into the paper before they ever resolve.
//
// THE ONE HARD RULE. There are no letterforms here and there is no font. What
// makes a mark read as WRITING is not its shapes, it is two facts about how it
// is arranged: strokes are thin curved things of varying width, and they sit in
// ROWS with blank between them. Give the eye those two facts and it supplies the
// language by itself, which is the whole trick and also the only honest way to
// do it: a shader that actually drew glyphs would be drawing someone's alphabet,
// and it would resolve, and resolving is the one thing this species must never
// do.
//
// So the strokes are RIDGED noise: 1 - |fBm|, whose level sets are continuous
// curves that thin and thicken along their length exactly the way a pen does.
// The rows are a band-limited cosine on a wandering baseline, because no hand
// writes on a rule. And the sharpening exponent is what ages them: raised, it
// thins the strokes until they break into fragments where the ridge dips, which
// is what happens to ink that has been scraped off a page.
//
// WHAT MOVES, and this is the species' real idea. Nothing does. Every other
// shader in this pack advects something: the blot creeps, the marble slides, the
// wick transports, the bed rocks, the mass drifts, the pool's sheen wanders. The
// writing here is IN the paper and the paper is not going anywhere. What moves
// is a slow surfacing field that decides, per place, how much of the sheet's
// memory is currently visible. The marks do not travel; your access to them
// does. That is what memory is like and it is the reason this reads as thought
// rather than as weather.
//
// AND WHY IT IS NOT THE SIGNAL FAMILY'S VEIL, which occupies the neighbouring
// register of almost-legibility. Veil is a stack of translucent scrims with a
// real transmittance chain: what is behind is dimmed by exactly what is in front
// of it, per pixel, and legibility is a matter of gaps opening in the layers.
// Nothing here is in front of anything. Both texts are in the same sheet at the
// same depth, and the one surfacing field gates them in OPPOSITION: where the
// field is high the newer hand comes up, where it is low the older one does, and
// in the wide middle both are half present. Two texts trading places in one
// surface, not two sheets seen through each other.
//
//   c0 layers     how far apart the two hands sit: angle, size of writing, and
//                 how sharply they trade
//   c1 legibility how close the strokes come to resolving. It is capped below 1
//                 on purpose and there is no setting that lets you read it
//   c2 surfacing  how far up the writing is allowed to come
//   c3 age        how eroded the older hand is: thinner, more broken, more gap
[[ stitchable ]] half4 mi_palimpsest(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    MIState st = mi_state(stateIndex, stateTau);
    float layers     = clamp(c0, 0.0, 1.0);
    float legibility = clamp(c1, 0.0, 1.0);
    float surfacing  = clamp(c2, 0.0, 1.0);
    float age        = clamp(c3, 0.0, 1.0);

    // THE ORB. A scribed ball: the ghost writing surfaces ON the sphere, its
    // line rhythm curved around the body as parallels of latitude. The page is
    // gone and the presence replaces it, which is a better home for this
    // species than the oval ever was: writing wrapped on a globe is legibly
    // writing and legibly not a document.
    MIOrb o = mi_orb(uv, mi_orb_radius(S));
    float3 sp = mi_spin(o.p, t * 0.030);

    // THE SWEEP. The envelope both drifts and evolves, and the drift is the
    // larger of the two: a field whose third coordinate runs faster than it
    // travels BOILS, and boiling is flicker, not surfacing. Surfacing is a
    // directional act, so a front of legibility crosses the body and the
    // writing comes up ahead of it and goes back down behind.
    float3 sweep = float3(-0.140, 0.100, 0.0) * (t * (1.0 + 1.5 * st.drive));
    float env = mi_noise3(sp * 2.0 + sweep + float3(0.0, 0.0, t * 0.030 + 19.0));
    float lift = 0.30 + 0.70 * smoothstep(-0.24, 0.30, env);

    // THE FLOURISH: one line surfaces closer to legible. A single band of the
    // body comes further up than the envelope was going to let it, holds at the
    // edge of being readable, and sinks. It works the species' OWN coordinate:
    // `lift` is the depth mechanism this whole shader is built on.
    MIBeat gl = mi_beat(t, 89.0, 2.4, 0.30);
    float ghost = gl.e * exp(-pow((-sp.y - (gl.id * 2.0 - 1.0) * 0.60) / 0.13, 2.0));
    lift = min(1.0, lift + 0.55 * ghost);

    // Two hands trading places in one surface: where the field is high the
    // newer comes up, where it is low the older does, and in the wide middle
    // both are half present. Nothing is in front of anything, which is what
    // separates this from the signal family's veil.
    float sep = 0.10 + 0.26 * layers;
    float gate = smoothstep(-sep, sep, env);
    float reach = (0.52 + 0.52 * surfacing) * lift;
    float visA = reach * gate;
    float visB = reach * (1.0 - gate) * (0.80 + 0.20 * layers);

    float px = max(fwidth(sp.x), 1e-5);
    float fine = 1.0 - smoothstep(0.012, 0.030, px);

    float writing = 0.0;
    for (int i = 0; i < 2; i++) {
        float fi = float(i);
        // The older hand is turned on the body and written smaller, because
        // nobody lines a new text up with the one they scraped off.
        float ha = 0.22 + fi * (0.55 + 0.90 * layers);
        float ca = cos(ha), sa2 = sin(ha);
        float3 e = float3(sp.x * ca + sp.y * sa2, -sp.x * sa2 + sp.y * ca, sp.z);

        // THE ROWS, as parallels of latitude on the ball, on a wandering
        // baseline because no hand writes on a rule. Three or four of them
        // across the presence: the rhythm of ruled writing is what says "text"
        // before any mark is read, and it only reads if you can count them.
        float lineFreq = 2.6 + 1.2 * fi * (0.4 + 0.6 * layers);
        float yl = (-e.y + 0.055 * sin(e.x * 2.3 + fi * 2.1)) * lineFreq;
        float wl = max(fwidth(yl), 1e-5);
        float attl = exp(-4.9348 * wl * wl);
        float row = 0.5 + 0.5 * cos(6.2831853 * yl) * attl;
        // The rows have to WIN: ink between the lines is the one thing that
        // stops a sheet of writing looking like a thicket.
        row = pow(row, 2.4);

        // THE STROKES. Ridged noise, whose level sets are continuous curves
        // that thin and thicken along their length exactly the way a pen does.
        // There are no letterforms here and no font: what makes a mark read as
        // writing is that strokes are thin curved things in ROWS, and a shader
        // that actually drew glyphs would be drawing someone's alphabet, and it
        // would resolve, and resolving is the one thing this must never do.
        //
        // Surfacing RISES: the marks are sampled a little further round the
        // body where it is giving them up, so a stroke lifts within its own
        // line as it comes and settles back as it goes. The rows do not move,
        // so nothing slides; only the ink comes up through the ruling.
        float scq = 1.0 - 0.28 * fi;
        float3 spn = float3(e.x * 5.4, (-e.y - 0.024 * lift) * 2.6, e.z * 5.4) * scq
                   + float3(0.0, 0.0, 11.0 + fi * 13.0);
        float ridge = saturate(1.0 - abs(mi_fbm3(spn, 2, 2.03, 0.5)) * (1.0 / 0.55));

        // Age erodes by SHARPENING: a higher exponent does not merely thin a
        // stroke, it breaks it wherever the ridge dips, which is exactly how
        // scraped ink fails. RESPONDING sharpens the hand: answering is the
        // body being clearer about what it says, never clear enough to read.
        float aged = age * fi;
        float sharp = 1.8 + 4.6 * legibility + 3.2 * aged + 1.8 * ghost * fi
                    + 0.9 * st.drive;
        sharp = mix(1.5, sharp, fine);
        float stroke = pow(ridge, sharp) * row;

        writing += stroke * (i == 0 ? visA : visB);
    }

    // The tooth of the body. One raw octave, the cheapest thing in the file,
    // and it is here because a presence with nothing on it between the writing
    // is not a scribed thing, it is a background.
    float tooth = mi_noise3(sp * 13.0 + float3(0.0, 0.0, 3.0));

    float tv = (0.048 + 2.05 * clamp(writing, 0.0, 1.2) * o.limb
             + 0.045 * (0.5 + 0.5 * tooth) * o.limb) * o.m;
    tv += mi_drink(st, saturate(0.5 - sp.y * 0.8)) * clamp(writing, 0.0, 1.2) * 0.30 * o.m;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}
