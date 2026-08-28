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
    return 1.0 - smoothstep(0.28, 0.46, length(uv));
}

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

    // The law. One exponential, read twice.
    MIState st = mi_state(stateIndex, stateTau);
    float tau = max(time - epoch, 0.0) * max(speed, 0.0);
    const float T = 1.25;
    float k = exp(-tau / T);                      // 1 at the drop, 0 arrived
    // RESPONDING: the blot pushes. A bounded advance on the front's own radius,
    // which is this species' one verb said louder.
    float Rinf = (0.19 + 0.15 * spread) * S * (1.0 + 0.13 * st.lean);
    float R = Rinf * sqrt(max(1.0 - k, 0.0));

    // The grain of the sheet, one fixed direction about 28 degrees off level.
    // It is fixed rather than dialled because a sheet has one grain and turning
    // it would be turning the paper, which is not a thing ink does.
    const float2 GRAIN = float2(0.8829, 0.4695);
    float2 landed = GRAIN * (0.040 * asym * S);
    float2 d2 = uv - landed;
    float rr = length(d2);
    float2 dir = rr > 1e-5 ? d2 / rr : float2(1.0, 0.0);
    float along = dot(dir, GRAIN);
    // An ellipse along the grain (the squared term, symmetric) plus one lobe
    // that reaches further downstream of where the drop landed (the linear
    // term). Fibre does both and a blot that only did the first looks turned
    // rather than absorbed.
    float aniso = 1.0 + asym * (0.24 * along * along + 0.11 * along);

    // The live edge. Two octaves, not three: fingering wants to be a handful of
    // broad tongues at 20 pt, and a third octave on a ring of this radius puts
    // detail below the sample spacing where it can only shimmer.
    // The fringe rate is what carries the verb once the arc is over. At 0.20 a
    // settled blot was a still picture with a faint crawl on it; at 0.32 the
    // fingers visibly reach and draw back, which is the thing a person names
    // when they say "it blooms". Responding widens the reach of that working.
    float ring = 0.8 + 1.0 * tearK;               // lobes around the front
    float fringe = mi_fbm3(float3(dir * ring, tau * 0.32 + 2.0), 2, 2.03, 0.5);
    // THE FLOURISH: a lobe runs. A blot does not keep spreading evenly. Every so
    // often one sector finds an easier run of fibre and pushes out ahead of the
    // rest, and then the front evens up again as the pressure equalises behind
    // it. A soft cosine sector aimed somewhere new each time, added to the
    // front's own radius and nowhere else, so the tide line and the wash follow
    // it out and back without a single term changing brightness.
    MIBeat gb = mi_beat(tau, 3.0, 2.2, 0.30);
    float ga = gb.id * 6.2831853;
    float lobe = pow(max(dot(dir, float2(cos(ga), sin(ga))), 0.0), 3.0);

    float Rf = R * aniso * (1.0 + (0.10 + 0.42 * tearK) * (1.0 + 0.45 * st.drive) * fringe)
                         * (1.0 + gb.e * 0.17 * lobe);

    float sd = Rf - rr;                            // > 0 inside the front
    // The front is a boundary in a wet porous medium, so it is never a rule: a
    // few per cent of the blot, and it scales with the blot so a small bloom is
    // a small bloom and not a sharp one.
    float w = 0.014 + 0.075 * Rinf;
    float core = smoothstep(-w, w, sd);

    // THE WASH. Water outruns pigment; there is always a dilute halo ahead of
    // the saturated part, and it is exponential because that is what a diffusion
    // profile is.
    float lt = 0.012 + 0.070 * tailK;
    float wash = exp(-max(-sd, 0.0) / lt) * (1.0 - core);

    // THE TIDE. Pigment piles up where the front stalls, so a blot is darker at
    // its edge than in its middle. It is the single most recognisable thing
    // about ink on paper and it is one gaussian.
    // THE RING IS THE FIGURE, so it is sized to be SEEN and not to be correct.
    // At 0.62 of the front's own softness the tide was about a pixel wide on a
    // 20 pt cell, which is a figure that exists only at 300 pt. A fifteenth of
    // the blot is thick for a real tide line and it is what makes the ring
    // legible at every size in the roster.
    float wr = 0.020 + 0.075 * Rinf;
    float tide = exp(-(sd * sd) / (wr * wr));

    // The interior, creeping outward forever at a vanishing rate. It is a
    // DILATION of the domain and not a radial pullback: pulling the sample
    // radius back by a fixed distance folds the domain at that radius, and the
    // fold draws a ring and a pinched knot at the centre of the blot. Dividing
    // the whole plane instead stretches the texture as the blot grows, which is
    // both artefact-free and the truer statement: the paper's mottling is not
    // sliding under the ink, the wetted region is getting bigger.
    float2 mp = d2 / (S * (1.0 + 0.62 * R));
    float mott = mi_fbm3(float3(mp * 5.2, tau * 0.070 + 12.0), 3, 2.03, 0.5);

    // The interior sits mid-rail and the TIDE is the brightest thing in the
    // picture. That ordering is the difference between ink and fruit: a blot
    // whose middle is its highlight reads as a lit sphere, and the first cut of
    // this shader did exactly that.
    float dens = core * (0.62 + 0.26 * mott) + 0.45 * wash;
    // THE THREE TIERS. Ink ground at 0.045, an amber body around 0.5, and the
    // ring taken all the way to the rail's pale stop. 0.54 is not a taste
    // choice: the body under the tide sits near 0.40, and the walk from the
    // tone to the cream specular does not begin until 0.78, so anything less
    // than this leaves the brightest pixel in the cell sitting in rust.
    float tv = 0.045 + 0.70 * clamp(dens, 0.0, 1.2)
             + (0.54 + 0.14 * tearK) * tide;
    // SUCCESS: the blot drinks from where the drop landed out to its own tide
    // line, so the saturation arrives the way the ink did.
    tv += mi_drink(st, rr / max(Rf, 1e-4)) * clamp(dens, 0.0, 1.2) * 0.26;

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
static inline float2 mi_rake(float2 p, float2 axis, float freq, float amp, float phase) {
    float2 across = float2(-axis.y, axis.x);
    return p + across * (amp * sin(dot(p, axis) * freq + phase));
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
    float2 p = uv / S;
    // The sheet slides. Seventeen thousandths of a frame a second at the
    // default: over ten seconds that is a sixth of the picture, which is felt
    // and not watched, and it means the same fold never sits in the same place
    // twice.
    p -= float2(0.86, 0.31) * (driftK * t * 0.058);

    // RESPONDING: the comb commits. The bath leans along the lay and the first
    // rake, the one that makes the gesture, is drawn deeper; the two answering
    // rakes are left where they were, so the sheet folds decisively in ONE
    // direction rather than merely folding harder everywhere.
    const float2 LAY = float2(0.2588, 0.9659);
    p -= LAY * (st.lean * 0.055);
    // ONE DOMINANT FOLD SYSTEM. There used to be three rakes at 7.3, 12.9 and
    // 21.7, and stacked at those pitches they made allover filigree: beautiful
    // at 300 pt and, at 20, a busy grey nothing with no shape to name. The
    // third is gone and the second is down to a quarter of the first, so what
    // is left is one gesture with a hand's worth of variation on it, drawn at a
    // coarser pitch so the folds are fewer and larger.
    float A = 0.050 + 0.075 * comb;
    p = mi_rake(p, float2( 0.9563,  0.2924),  5.4, A * (1.0 + 0.55 * st.drive), t * 0.57);
    p = mi_rake(p, float2(-0.4067,  0.9135),  9.5, A * 0.28, -t * 0.41 + 1.7);

    // THE FLOURISH: a fourth comb stroke. The three rakes above are the ones
    // always in the bath. This is the marbler picking the comb up and drawing it
    // through once more, at a new angle each time, then setting it down. It is
    // the same operator as the other three and so it is still a shear: the extra
    // fold moves ink without making any, which is why the pattern that comes
    // back afterwards is the pattern that was there before, carried somewhere
    // new rather than churned.
    MIBeat gm = mi_beat(t, 11.0, 2.4, 0.28);
    float gAng = gm.id * 3.1415927;
    p = mi_rake(p, float2(cos(gAng), sin(gAng)), 9.7,
                (0.055 + 0.045 * comb) * gm.e, t * 0.44 + gm.id * 6.2831853);

    // The sheet of ink the comb is drawn through. Broad: three octaves off a
    // base of 2.4 tops out around ten cycles a frame, which is structure a
    // 20 pt indicator can still hold.
    float sheet = mi_fbm3(float3(p * 2.4, t * 0.046 + 21.0), 3, 2.03, 0.5);

    // Band phase in CYCLES, built from the sheet plus a gentle lay direction so
    // the laminae have a grain to run along instead of closing into rings.
    // THE STONE. The marbling is now an OBJECT floating in the cell rather
    // than a pattern filling it: the sheet's own field against a radial well,
    // the same construction the halation body uses, which guarantees a single
    // closed outline (the pedestal keeps the centre inside it at any noise
    // value) while leaving the noise to decide the shape. It combs with the
    // rest of the bath, because a skin of ink on water does move when the comb
    // goes through it.
    // The stone's outline gets its OWN field, and that is not a luxury. Built
    // from `sheet` it was a level set of the same scalar the band phase is
    // built from, so the outline ran parallel to a vein: the edge of the object
    // and the brightest line inside it were the same curve, and the result read
    // as a hollow loop of bright scribble rather than as a body of ink. One raw
    // octave on the UNRAKED frame keeps the two independent, and it costs eight
    // hashes. It does not comb with the bath either, which is right: the skin
    // of ink has a shape of its own that the comb moves through.
    float stoneN = mi_noise3(float3(uv * 1.7, t * 0.030 + 61.0));
    float stoneF = 0.46 + 0.55 * stoneN - 3.2 * dot(uv, uv);
    float stone = smoothstep(-0.02, 0.14, stoneF);

    // 1.65 at the default, not the 1.07 the first cut of the reshape used.
    // "Fewer and larger" overshot into "one": at that count a single vein
    // survived and a lone contour snaking through a blob is not a marbled mass,
    // it is a doodle. Three or four folds is the count where the object still
    // reads as folded at 20 pt and still has folds to look at at 300.
    float count = 0.90 + 1.50 * folds;
    float u = (sheet * 2.1 + dot(p, float2(0.2588, 0.9659)) * 1.35) * count;

    float wpx = max(fwidth(u), 1e-5);                  // cycles per device pixel
    float att = exp(-4.9348 * wpx * wpx);              // exp(-(pi w)^2 / 2)
    float s = 0.5 + 0.5 * cos(6.2831853 * u) * att;
    float body = pow(s, 1.0 + 2.4 * contrast);

    // Distance to the nearest band crest, in cycles, converted to PIXELS by the
    // same derivative. A vein is then about 1.7 px of half-width at every size,
    // which is what keeps a drawn line looking drawn at 300 pt and stops it
    // becoming a strobe at 20.
    // THE VEIN IS A RIBBON, NOT A HAIRLINE, and this is a units correction. It
    // used to be measured purely in PIXELS, which is right for an isoline on a
    // survey sheet and wrong for a fold of ink: at 300 pt a fold's bright ridge
    // came out two pixels wide and the whole species read as a contour drawing
    // of marbling rather than as marbling. A fold's ridge is a fraction of the
    // fold, so the width is now a fraction of the BAND, with a pixel floor
    // underneath it so that at 20 pt, where a seventh of a band is a third of a
    // pixel, it still has something to draw.
    float dc = abs(fract(u + 0.5) - 0.5);           // cycles to the nearest crest
    float halfW = max(0.145, 1.8 * wpx);            // in cycles, floored in pixels
    float vein = exp(-(dc * dc) / (halfW * halfW)) * att;

    // A floor under the body so the stone reads as one filled mass with folds
    // in it rather than as a set of separate stripes that happen to be near
    // each other. The troughs stay well down the rail; they just stop being the
    // ink ground, which is what makes the object cohere.
    float mass = (0.20 + 0.80 * mix(saturate(0.5 + 0.85 * sheet), body, att)) * stone;
    // The three tiers: ink outside the stone, amber in it, and the veins taken
    // to the rail's cream stop. The vein is deliberately driven a little past
    // 1.0 so that its crest saturates into the pale specular and its shoulders
    // fall back through the tone, which is what puts a bright line on an amber
    // body instead of a uniformly hot smear.
    float tv = 0.055 + 0.62 * mass + (0.32 + 0.14 * contrast) * vein * stone;
    // SUCCESS: the folds take up pigment in sequence along the lay, so the
    // saturation reads as something moving through the bath rather than the
    // bath being turned up.
    tv += mi_drink(st, saturate(0.5 + dot(p, LAY) * 1.15)) * (mass + 0.6 * vein) * 0.26;

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
    float2 q = float2(uv.x, -uv.y);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float climb   = clamp(c0, 0.0, 1.0);
    float fiber   = clamp(c1, 0.0, 1.0);
    float pooling = clamp(c2, 0.0, 1.0);
    float dry     = clamp(c3, 0.0, 1.0);

    // Jurin: the equilibrium height, and the spread of it across the sheet.
    float h0 = -0.19 + 0.42 * climb;
    // The wet line carries this species and it took the largest lift in the
    // pack, more than the 2x the others were held to. The reason is geometric,
    // not a matter of taste: the fibre grain below is stretched seven to one up
    // the sheet, and sliding a long vertical streak ALONG its own axis produces
    // almost no visible change, so the transport term can be lifted all day and
    // the style still reads frozen. What the eye actually reads as motion here
    // is the line seeking its level, so that is where the tempo had to go.
    float rag = mi_fbm3(float3(q.x * (5.5 / S), 0.0, t * 0.175 + 4.0), 3, 2.03, 0.5);
    float front = h0 + (0.050 + 0.100 * fiber) * rag;

    // THE FLOURISH: one thread runs ahead. A single fibre, narrower than the
    // raggedness of the line itself, that carries ink well past where the rest
    // of the front has stalled and then lets it fall back as the pore drains.
    // This is the one thing in a wicking sheet that looks like a decision, and
    // it happens in the front's HEIGHT, so the tide line and the concentration
    // gradient run up the thread with it.
    MIBeat gw = mi_beat(t, 23.0, 2.0, 0.26);
    float xg = (gw.id * 2.0 - 1.0) * 0.34 * S;
    float dxg = (q.x - xg) / (0.045 * S);
    front += gw.e * (0.18 + 0.10 * climb) * exp(-dxg * dxg);

    // RESPONDING: the ink pushes up the sheet. A bounded advance on the front,
    // which is this species saying its own verb harder.
    front += st.lean * 0.085;

    float sd = front - q.y;                        // > 0 wet
    float wEdge = 0.030 - 0.018 * dry;
    float wet = smoothstep(-wEdge, wEdge, sd);

    // The tooth of the paper: high frequency across the fibres, low along them,
    // which is what makes the texture read as fibre rather than as noise.
    //
    // THE RATIO IS A COMPROMISE AND IT MOVED. At seven to one the striation was
    // beautiful and the style had no verb: a streak that long is nearly
    // invariant under sliding along its own axis, so the transport term was
    // running and nothing could be seen to climb. At four to one there is
    // enough structure ALONG the fibre for the eye to follow a feature up the
    // sheet, and the striation still reads as fibre and not as mottle. The
    // whole species is called wick; the climb has to be visible.
    float3 gp = float3(q.x * (13.0 / S), (q.y - t * 0.085) * (3.4 / S), 9.0);
    float grain = mi_fbm3(gp, 2, 2.03, 0.55);

    // The concentration gradient a chromatogram has: strong at the source,
    // exhausted at the front.
    float conc = mix(0.52, 1.0, saturate(sd / 0.42));

    // The fringe line is this species' figure and it is widened for the same
    // reason the blot's ring was: a cream line a pixel wide is not a figure.
    float wr = 0.022 + 0.030 * (1.0 - dry);
    float tide = exp(-(sd * sd) / (wr * wr));

    // The foot of the sheet stands in the reservoir.
    float src = 1.0 - smoothstep(-0.42, -0.12, q.y);

    float dens = wet * conc * (0.80 + 0.85 * fiber * grain) + pooling * 0.42 * src;
    float tv = 0.045 + 0.64 * clamp(dens, 0.0, 1.3)
             + (0.70 + 0.20 * dry) * tide
             // Dry paper is not blank paper. A whisper of tooth above the line
             // is most of what makes this interesting at 300 pt and it costs
             // nothing: the grain tap is already paid for.
             + 0.050 * (1.0 - wet) * (0.5 + 0.5 * grain);
    // SUCCESS: the climb saturates root to tip. q runs from the reservoir at the
    // foot to the wet line, so the surge travels the way the ink travelled.
    tv += mi_drink(st, saturate((q.y + 0.42) / max(front + 0.42, 1e-3)))
        * wet * conc * 0.26;

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

    // The lean, plus the rock the vessel never loses.
    // The vessel's rock, damped while responding: holding still is what
    // decisiveness looks like in a species whose subject is coming to rest.
    float rock = 1.0 - 0.55 * st.drive;
    float ang = (tiltK - 0.5) * 0.40
              + rock * (0.035 * sin(t * 0.31) + 0.022 * sin(t * 0.19 + 2.1));
    float ca = cos(ang), sa = sin(ang);
    float xAc =  uv.x * ca + (-uv.y) * sa;
    float yUp = -uv.x * sa + (-uv.y) * ca;

    float rip = mi_fbm3(float3(uv * (2.6 / S), t * 0.128 + 31.0), 2, 2.03, 0.5);
    float y = yUp + disturb * 0.045 * rip;

    // THE STACK, and this is the reshape. This species used to be one
    // anisotropic field whose level sets happened to lie flat, which fills the
    // circle with stripes; stripes are a texture and a texture has no
    // silhouette. A settled bed is a THING with a top. So the surface is now
    // built explicitly, the courses are measured DOWN FROM IT so they are
    // parallel to it and move with it, and the line along it is the figure's
    // key structure and the cell's cream.
    //
    // The arc drives the surface instead of driving an anisotropy: turbid, it
    // sits high and is soft enough to be no surface at all, which is a cloud
    // filling the vessel; settled, it drops to a low mound with a crisp top and
    // the courses separate under it. Same exponential, a legible object.
    float mound = exp(-(xAc * xAc) / 0.30);
    float wob = mi_noise3(float3(xAc * (3.4 / S), 0.0, tau * 0.05 + 51.0));

    // THE FLOURISH lifts the SURFACE now rather than the band coordinate, which
    // is what "a lens of the bed lifts and resettles" actually looks like when
    // the bed has a top to lift.
    MIBeat gs = mi_beat(t, 37.0, 2.4, 0.34);
    float xg = (gs.id * 2.0 - 1.0) * 0.30;
    float dxs = (xAc - xg) / 0.16;
    float lens = gs.e * 0.055 * exp(-dxs * dxs);

    // RESPONDING: the heap draws itself in and settles lower, which is this
    // species' own arrival pushed past where it would have stopped.
    float surfY = mix(0.42, -0.02 + 0.13 * mound + 0.035 * wob, clear)
                + lens - 0.035 * st.drive;
    float below = surfY - y;                       // > 0 inside the bed
    float ws = mix(0.30, 0.022, clear);            // the surface's own softness
    float inBed = smoothstep(-ws, ws, below);

    // THE COURSES. Three or four of them across the depth of the heap, banded
    // on a cosine so each one has a top and a bottom, perturbed by the field so
    // no two are the same thickness. Band-limited by fwidth like the marbling's
    // laminae, so at 20 pt they dissolve into the mass instead of aliasing.
    float bandN = (2.6 + 2.4 * layers) / 0.45 * (1.0 + 0.22 * st.drive);
    float nz = mi_fbm3(float3(xAc * (2.4 / S), y * (2.2 / S), tau * 0.045 + 3.0),
                       2, 2.03, 0.5);
    float bp = below * bandN + 0.42 * nz;
    float wpx = max(fwidth(bp), 1e-5);
    float att = exp(-4.9348 * wpx * wpx);
    float band = 0.5 + 0.5 * cos(6.2831853 * bp) * att;
    band = mix(0.5, pow(band, 1.0 + 1.6 * layers), clear);

    // The courses low in the stack carry more than their share, because
    // everything above them is pressing down.
    float comp = 1.0 + 0.45 * saturate(below / 0.40);
    float dens = inBed * (0.40 + 0.60 * band) * comp * (0.72 + 0.28 * (0.5 + 0.8 * nz));

    // The supernatant. Never clear, and it is where the turbidity lives while
    // the arc is still running.
    float haze = (1.0 - inBed) * (0.30 + 0.70 * k) * saturate(0.5 + 0.9 * nz);

    // THE SURFACE LINE: the figure's silhouette, and the only thing in this
    // cell that reaches the rail's pale stop. It arrives with the settling,
    // because before there is a bed there is nothing for a surface to be.
    float line = exp(-(below * below) / (0.030 * 0.030)) * clear;

    float tv = 0.045 + 0.52 * clamp(dens, 0.0, 1.4) + 0.10 * haze + 0.72 * line;
    // SUCCESS: the saturation rises through the stack, bottom course first.
    tv += mi_drink(st, 1.0 - saturate(below / 0.45)) * clamp(dens, 0.0, 1.4) * 0.26;

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

    // THE PITCH, twice revised, and the second revision undoes the first for a
    // reason. It started at 2.3 and the level set broke into four or five
    // separate islands: a maze of lit edges, not a mass. Dropping it to 1.8
    // fixed that, but only because there was no radial well yet. With the well
    // added, closure is guaranteed by the pedestal rather than by keeping the
    // noise coarse, and 1.8 turned out to cost the species its verb: at barely
    // one cycle across the body the field can only translate the whole mass, so
    // it wobbled instead of reforming. At 2.9 there are three or four lobes on
    // the body, each big enough to watch swell and be absorbed as the domain
    // turns, and the well still guarantees they belong to one thing.
    const float F = 2.9;                            // domain scale, cycles a frame
    float2 p = uv / S;

    // THE REFORM, and this is the rebuild. The mass used to change by drifting
    // through the noise's third coordinate, and a field evolving in its own z
    // has no direction: lobes appeared and vanished where they stood, which the
    // eye reads as flicker or as noise wandering, never as a body doing
    // something. Nobody could name that motion.
    //
    // So the domain TURNS. Rotating the sample frame about the centre while the
    // well holds the body in place makes the lobes travel around the mass:
    // one swells on this shoulder, rides around, and is absorbed on the other
    // side. That is a nameable verb, it is what a dense thing suspended in
    // something does, and it costs one sine and one cosine. The z drift stays
    // but at a third of its old rate, so the shape still changes as it turns
    // instead of being one rigid silhouette rotating, which would read as a
    // logo spinning.
    //
    // The gain also drops from 0.5 to 0.42. Larger, fewer lobes: a lobe has to
    // survive long enough to be watched arriving and leaving, and at the old
    // gain the silhouette carried so much fine detail that no single feature
    // was legible for the three seconds it takes to name a motion.
    float spin = t * (0.075 + 0.14 * morph);
    float cs = cos(spin), sn = sin(spin);
    float2 pr = float2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
    float3 q = float3(pr * F + float2(0.018, -0.013) * t,
                      t * (0.022 + 0.055 * morph) + 6.0);
    float4 Fd = mi_fbmd3(q, 3, 2.03, 0.42);
    // THE BIAS, and without it this style does not exist. The level set of a
    // plain fBm is a winding curve that crosses the whole frame, so lighting
    // its edge draws a long lit ribbon: the picture has a bright thing in it
    // and no body. A radial well makes the field highest at the centre, which
    // turns that same level set into a closed, lobed silhouette sitting where
    // the eye already is.
    //
    // The three constants are a guarantee and not a taste. 0.42 is the pedestal
    // and 0.55 scales the noise to about +/- 0.30 against it, so the field at
    // the centre can never fall to the threshold however the noise lands: there
    // is ALWAYS a mass. Without that the body would blink out whenever the fBm
    // happened to be low at the middle of the frame, and it did, which is a
    // thinking indicator that stops having a subject. B = 4.5 then sets the
    // size: the radius runs between about 0.16 and 0.40 of the frame, so the
    // body is always inside the shore and always big enough to read at 20 pt.
    // The noise still owns the shape, moving the boundary by forty per cent of
    // its own radius, which is a lobed mass rather than a circle with texture.
    // RESPONDING: the body draws itself in. A tighter well is a denser, more
    // compact mass, which is what a thing about to answer looks like.
    float B = 4.5 * (1.0 + 0.22 * st.drive);

    // THE FLOURISH: the mass leans and returns. The radial well is what holds
    // the body together, so moving the well is moving the body: for a couple of
    // seconds its centre of gravity slides off centre in some direction and then
    // comes back. The silhouette stretches on one side and gathers on the other
    // while it goes, because the noise it is cut from does not travel with it,
    // which is the difference between a mass shifting its weight and a sticker
    // being slid across the frame.
    MIBeat gh = mi_beat(t, 53.0, 2.3, 0.32);
    float gha = gh.id * 6.2831853;
    float2 uvc = uv - float2(cos(gha), sin(gha)) * (gh.e * 0.052)
                    - float2(0.80, -0.60) * (st.lean * 0.045);

    float f = 0.42 + 0.55 * Fd.x - B * dot(uvc, uvc);
    // The chain rule, and it is not optional: the gradient comes back in the
    // noise domain, and a distance measured there is not a distance on screen.
    // The well's own gradient is carried with it, or the distance estimate is
    // wrong by exactly the term that makes the body a body.
    // The gradient comes back in the SPUN frame, so it is rotated out of it
    // before anything measures a distance with it. The rotation is orthonormal,
    // so its inverse is its transpose and this is two multiplies; skipping it
    // would tilt the halo's width away from the body by exactly the spin angle,
    // which would look like the glow slipping off its own mass.
    float2 gq = 0.55 * Fd.yz * (F / S);
    float2 g = float2(gq.x * cs + gq.y * sn, -gq.x * sn + gq.y * cs) - 2.0 * B * uvc;
    float gl = max(length(g), 1e-3);

    // The threshold sits ABOVE the field's mean, so the body is the minority of
    // the frame: about a quarter of it at the default. Sitting it at the mean,
    // which is where it started, splits the frame half and half and the eye
    // cannot tell which half is the mass.
    float thr = mix(0.26, -0.20, massK);
    float d = (f - thr) / gl;                       // signed distance, in frames
    float inside = smoothstep(-0.004, 0.010, d);

    float2 nOut = -g / gl;                          // f falls outward, so this does
    float a = offset * 6.2831853;
    float facing = 0.5 + 0.5 * dot(nOut, float2(cos(a), sin(a)));

    // Halation is a GLOW and not an outline, so the corona is wide and the rim
    // is only the hot core of it. Weighted the other way round the mass wears a
    // drawn edge, which is the one thing a scattering effect never looks like.
    float w = 0.022 + 0.100 * corona;
    float halo = exp(-max(-d, 0.0) / w) * (1.0 - inside);
    // The rim carries the cream, so it is wide enough to carry it at 20 pt.
    float wr = 0.020 + 0.024 * corona;
    float rim = exp(-(d * d) / (wr * wr));
    // The body is dark but it is not a hole. It holds the rail's deep shadow at
    // its shoulder and gives even that up toward its middle, so there is ink in
    // there and not an absence. The 0.20 falloff is measured against the body's
    // own radius rather than chosen: much tighter and the shadow lives only in
    // the few points nearest the edge, which at 46 pt is a stroked ring with
    // nothing inside it. A mass has to have an inside.
    float core = 0.20 * exp(-max(d, 0.0) / 0.20);

    // THE FLOOR ON THE FACING TERM, and it is a correction from the calibration
    // pass. Weighting the corona 0.35 to 1.0 by how much the boundary faces the
    // light is the right instinct and it was too deep: over the reforming cycle
    // there are states where little of the silhouette faces the source, and in
    // those the whole ring went soft and the cell nearly disappeared beside its
    // siblings in the gallery. 0.62 to 1.0 keeps the asymmetry (the lit shoulder
    // is still two thirds brighter than the far one) while making a complete
    // corona the MINIMUM rather than the average. The species is a mass wearing
    // its own light; the light is never allowed to leave it.
    //
    // Note what this is not. The lift is on the floor and not on the peak, so
    // nothing about it is a pulse: the bright side is exactly as bright as it
    // was, and no term here varies with time that did not vary before.
    float tv = 0.040
             + inside * core
             + (0.22 + 0.60 * corona) * halo * (0.62 + 0.38 * facing)
             + (0.36 + 0.24 * corona) * rim  * (0.35 + 0.65 * facing);
    // SUCCESS: the scatter drinks outward from the body's own edge, so the
    // arrival travels through the corona rather than switching it on.
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

    float lean = (tiltK - 0.5) * 2.0;
    float2 low = float2(0.6428, 0.7660) * lean;

    float2 dv = uv - low * (0.030 * S);             // ink gathers on the low side
    float rr = length(dv);
    float2 dir = rr > 1e-5 ? dv / rr : float2(1.0, 0.0);

    // The shore, read on a ring so it is periodic in theta with no seam, and
    // The shore CREEPS. This is the correction the motion pass demanded: at
    // 0.026 the rim was mathematically moving and visually frozen, and a still
    // pool that looks like a photograph of a pool has failed at being the
    // stillest species rather than succeeded at it. Stillness has to be
    // observed to be stillness: something must be seen to be barely moving.
    // 0.048 is still the slowest clock in this file by a wide margin, and it is
    // enough that the wetted edge is visibly finding its level.
    float rimN = mi_fbm3(float3(dir * 1.35, t * 0.048 + 17.0), 2, 2.03, 0.5);
    float R = (0.225 + 0.070 * tension) * S * (1.0 + 0.20 * rimN);

    // A spherical cap, leaned, raised to 1.6. The exponent is the difference
    // between a dish of ink and a lit disc: a plain cap is bright almost all
    // the way out and its edge is the only event in the picture, whereas the
    // steeper falloff leaves a DARK ANNULUS of shallow ink for the meniscus to
    // be seen against. The light in this style is supposed to be at the wall
    // and in the reflection, not spread evenly over the middle.
    float x = clamp(rr / max(R, 1e-4), 0.0, 1.0);
    float cap = sqrt(max(1.0 - x * x, 0.0));
    float h = pow(cap, 1.6) * (1.0 + 0.28 * dot(dv, low) / max(R, 1e-4));
    h = max(h, 0.0);

    // The surface, and its slope, in one tap.
    // The surface both EVOLVES and DRIFTS. Evolving alone changes the highlight
    // where it stands, which reads as a shimmer with no direction; the small
    // lateral drift is what makes the reflection travel across the dish, and a
    // travelling highlight is the thing a person names when they say the water
    // is alive. RESPONDING pushes that drift, which is all the urgency this
    // species is allowed: it answers by moving its light, not by moving itself.
    const float SF = 3.1;
    float2 sDrift = float2(0.026, -0.018) * (t * (1.0 + 1.6 * st.drive));
    float4 Sf = mi_fbmd3(float3(uv * (SF / S) + sDrift, t * (0.062 + 0.130 * tremor) + 41.0),
                         3, 2.03, 0.5);
    float2 slope = Sf.yz * (SF / S) * (0.024 + 0.060 * tremor);

    // The shore, anti-aliased by the same derivative the marbling uses, so the
    // edge of the pool is one pixel at 20 pt and one pixel at 300 pt.
    float e = max(fwidth(rr), 1e-5);
    float pool = 1.0 - smoothstep(R - e, R + e, rr);

    // Jurin from the other side: the liquid climbs the wall over its capillary
    // length, and that climb tips the surface outward.
    // Widened, because the meniscus is now the figure's key line and has to
    // carry cream at 20 pt rather than merely exist at 300.
    float lambda = (0.018 + 0.030 * tension) * S * (1.0 - 0.22 * st.drive);
    float men = exp(-max(R - rr, 0.0) / lambda) * pool;
    // Almost all of the meniscus goes into the SLOPE and only a little into the
    // brightness, and that split is the whole reason this shader is allowed to
    // have a rim at all. Light added directly at the wall paints a ring, and a
    // ring is a drawn circle. Tipping the surface there instead lets the same
    // overhead light decide: the wall catches a bright ARC where it faces the
    // source and stays dark where it turns away, which is what a dish of ink on
    // a table actually looks like and is not a shape anybody drew.
    slope += dir * (men * (0.34 + 0.40 * tension));

    // THE FLOURISH: one ring from an unseen touch, and it is the smallest
    // gesture in the pack because this is the stillest species in it. Something
    // met the surface somewhere off to one side and a single ripple runs out
    // from it and dies.
    //
    // It is added to the SLOPE and contributes no light of its own, exactly like
    // the meniscus above and for the same reason: a ring painted as brightness
    // is a drawn circle, while a ring that tips the surface is caught by the one
    // overhead light and therefore arrives as a bright arc on the side facing
    // the source and a dark one on the other. You see the water move, not a
    // shape appear.
    //
    // The profile is x*exp(-x^2), the derivative of a gaussian, because that is
    // literally what the slope of a single ripple crest looks like: a rise and
    // an equal fall with no net displacement left behind. The 2.33 normalises
    // its peak to one. The crest travels outward on the gesture's own phase, so
    // it expands and fades rather than blinking.
    MIBeat gp = mi_beat(t, 71.0, 2.4, 0.22);
    float rga = gp.id * 6.2831853;
    float2 dR = uv - float2(cos(rga), sin(rga)) * ((0.10 + 0.10 * gp.id) * S);
    float rg = length(dR);
    float xr = (rg - gp.k * 0.34 * S) / (0.055 * S);
    float ripple = 2.33 * xr * exp(-xr * xr);
    slope += (rg > 1e-5 ? dR / rg : float2(0.0)) * (gp.e * 0.052 * ripple * pool);

    // The light sits nearly overhead, a little to the upper left. Nearly is
    // load bearing: put it out at forty degrees and a flat surface returns
    // almost nothing through a high exponent, and the pool goes black except
    // where it happens to tip. Overhead, a still surface is quietly lit and the
    // tremor MODULATES that instead of switching it on.
    const float3 LIGHT = float3(-0.18470, -0.26678, 0.94581);
    float3 nrm = normalize(float3(-slope, 1.0));
    float spec = pow(saturate(dot(nrm, LIGHT)), 9.0 + 16.0 * sheenK);

    // The dried tide just outside the wet edge, where an earlier fill retreated
    // and left its pigment behind. Invisible at 20 pt, and the reason the shore
    // reads as ink rather than as a cut at 300.
    float dq = (rr - R - 0.012 * S) / (0.011 * S);
    float dried = exp(-dq * dq) * (1.0 - pool);

    float tv = 0.045
             + 0.30 * h * pool
             + (0.22 + 0.32 * sheenK) * spec * pool
             // THE CREAM LINE. Earlier this shader argued that light added at
             // the wall paints a ring and a ring is a drawn circle, and it kept
             // the meniscus almost entirely in the slope for that reason. The
             // figure law overrules it: this species' one nameable structure IS
             // the wetted edge, and a figure whose key structure never leaves
             // rust is unreadable at 20 pt. The slope contribution stays, so
             // the light still falls on the wall from a direction and the line
             // is brighter where it faces the source; what changed is that the
             // line now reaches the top of the rail where it is lit.
             + (0.58 + 0.20 * tension) * men
             + 0.075 * dried;
    // SUCCESS: the dish takes up pigment from the middle out to the meniscus,
    // so the last thing to saturate is the wall, where the light already is.
    tv += mi_drink(st, saturate(rr / max(R, 1e-4))) * (h * pool + 0.7 * men) * 0.26;

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

    // The grain of the sheet. The 0.45 offset is so the default knob (0.5) lands
    // on a diagonal rather than square on an axis: a plume running dead
    // horizontal reads as a diagram, and a plume running dead vertical starts to
    // borrow the wick's composition.
    float ang = dirK * 6.2831853 + 0.45;
    float2 a = float2(cos(ang), sin(ang));
    float2 b = float2(-a.y, a.x);
    float s = dot(uv, a);
    float n = dot(uv, b);

    // The law. L0 is not zero: the pen touched down before it bled, so there is
    // a mark to feather OUT of rather than a species that begins as an empty
    // frame.
    const float T = 1.45;
    float L0 = 0.05 * S;
    // THE PROPORTIONS, and they are a correction. The first cut ran four times
    // as long as it was wide from a source pushed right out to the edge of the
    // frame, and a long thin bright thing entering from off-stage is a comet
    // however it is textured: the eye reads elongation plus a leading edge as
    // SPEED before it reads anything else. A stain is not much longer than it is
    // wide and it sits where it started. So the reach came in, the width went
    // out, and the source moved toward the middle of the frame. The species is
    // still directional, because the ink still runs along the grain and barely
    // across it, but the direction is now a bias in a spreading mark rather than
    // a trajectory through empty space.
    // RESPONDING: the bleed advances confidently. A bounded push on the reach,
    // which is the one thing this species does, done with conviction.
    float Linf = (0.28 + 0.21 * bleed) * S * (1.0 + 0.15 * st.lean);
    float L = Linf + (L0 - Linf) * exp(-tau / T);

    float sSrc = -0.15 * S;
    float u = s - sSrc;                            // 0 at the source, forward is +
    float uN = saturate(u / max(Linf, 1e-4));      // 0 at the root, 1 at full reach

    // THE FLOURISH: the tip bends to a new fibre and back. A bleed does not run
    // down one bundle forever; it finds a neighbouring one, leans across into it
    // and drifts back. Applied across the fibre and weighted by uN SQUARED, so
    // the root stays pinned exactly where the pen put it and only the reach
    // swings, which is the curtain's own pinned-at-the-crest trick borrowed into
    // a horizontal species. It enters before the comb and the cross-section are
    // read, so the whole plume bends: teeth, striation and edges together, and
    // not a rigid rotation of a finished picture.
    MIBeat gf = mi_beat(tau, 5.0, 2.2, 0.30);
    n += (gf.id * 2.0 - 1.0) * gf.e * 0.075 * uN * uN * S;

    // The width the fan settles at, needed before the comb because the comb is
    // measured against it.
    float Wref = (0.115 + 0.085 * bleed) * S;

    // THE COMB. One slice of the 3D field taken across the fibres, with time in
    // the third coordinate so the teeth work in place instead of sliding along
    // the edge. A comb that slides is a zip; a comb that breathes is capillary.
    //
    // The pitch is counted across the PLUME and not across the frame, and that
    // is the whole difference between a comb and a staircase. Measured against
    // the frame, a plume a sixth of the frame wide catches two or three cells of
    // the noise and its leading edge becomes three enormous blocks; measured
    // against its own width it always carries the same number of teeth however
    // wide it has grown, which is what a fibre count actually means.
    float pitch = 3.2 + 6.5 * fiber;
    float hair = mi_fbm3(float3(n * (pitch / max(Wref, 1e-4)), 0.0, tau * 0.22 + 3.0),
                         2, 2.03, 0.5);
    float Lh = L * (1.0 + (0.05 + 0.13 * fiber) * hair);

    // THE GRAIN, and this is the rebuild. The first cut treated the sheet as a
    // faint texture painted inside a smooth silhouette, and that is backwards:
    // ink feathering has no silhouette. It advances along individual fibres, and
    // what looks like an edge is only the place where fewer and fewer of them
    // are still carrying anything. So this field is not decoration on the form,
    // it IS the form. One value, deep, in 0 to 1, and it decides three things at
    // once: how far this fibre carries ink, how far out to the side the plume
    // reaches here, and how much ink is at this point at all.
    //
    // That is what makes the boundary fibrous in EVERY direction rather than
    // only at the leading edge. A fibre with capacity runs on past its
    // neighbours and a starved one falls short, at the flanks exactly as much as
    // at the tip, so no part of the outline is a curve anybody drew.
    // The anisotropy is 4:1 and not the 12:1 the first rebuild used. Paper fibre
    // is SHORT. Stretched twelve to one the grain becomes continuous channels
    // running the whole length of the mark, and parallel lines along the
    // direction of travel are motion blur: the texture that was supposed to say
    // "this ink is in a sheet" said "this thing is moving fast" instead. Broken
    // into short lengths it reads as what it is.
    float grain = mi_fbm3(float3(n * (26.0 / S), s * (7.0 / S), 21.0 + tau * 0.050),
                          2, 2.03, 0.55);
    float fibre = saturate(0.5 + 0.95 * grain);

    // The lateral envelope is a plain gaussian again. The super-gaussian that
    // was here traded one fault for a worse one: it flattened the axial beam by
    // steepening the shoulders, and steep shoulders on a long form are precisely
    // the straight flanks that made this read as a brush stroke. The soft
    // profile comes back, and the beam does not come back with it, because the
    // grain below breaks the middle into fibres so there is no smooth core left
    // to read as a beam.
    // THE TEARDROP. The width used to GROW along the bleed, which fans and
    // reads as a wedge; a feather is broad at the head and tapers to a tip.
    // Widest just past the root and down to a third of that at the reach, which
    // with the reach's own lateral falloff gives a plume with a rounded head, a
    // clear orientation and a point.
    float W = Wref * (1.22 - 0.86 * uN) * (0.72 + 0.56 * fibre);
    float across = exp(-(n * n) / max(W * W, 1e-8));

    // Each fibre's own reach, and it has to FALL OFF TO THE SIDES or the mark
    // never closes. Cutting the front at a constant distance along the grain
    // makes the boundary a level set of one coordinate: a straight line with
    // teeth on it, which is a serrated blade however finely the teeth are cut,
    // and it was the last hard edge in this species. The fibres out at the
    // flanks are further from where the pen touched down and carry ink less far,
    // so the reach is weighted by how far out the fibre sits. That single term
    // turns the outline from a cut end into a closed curve, and the grain then
    // makes the whole of that curve ragged instead of only its front.
    float lateralFall = exp(-(n * n) / max(2.6 * Wref * Wref, 1e-8));
    float reach = Lh * (0.82 + 0.30 * fibre) * (0.40 + 0.60 * lateralFall);
    float w = 0.028 + 0.095 * Linf;
    float front = smoothstep(-w, w, reach - u);
    // Behind the source the ink creeps too. It is given more room than the first
    // cut allowed, because a mark that only spreads forward is a jet: a stain
    // wets the paper it started on as well as the paper in front of it.
    float bw = 0.10 * S;
    float back = smoothstep(-bw, bw, u + (0.16 + 0.05 * fibre) * S);

    // Chromatography, but gently. A strong fall from root to tip is a fade along
    // the direction of travel, which the eye reads as a motion streak; the real
    // gradient in a feathered mark is mild, because the whole point is that the
    // ink got carried.
    float sat = mix(1.0, 0.82, uN);

    // The tip, where a fibre stalls and its pigment piles up. It rides the
    // fibre's own reach, so the tide line is as ragged as the front is.
    float dTip = reach - u;
    float wt = (0.014 + 0.032 * (1.0 - dryness)) * S;
    float tip = exp(-(dTip * dTip) / max(wt * wt, 1e-8)) * back;

    // THE SUBSTRATE. A wider, softer copy of the same envelope carrying the same
    // grain, so the sheet is faintly legible just past where the ink got to.
    // Without it the plume hangs in an empty black field and reads as an object
    // flying through a void; with it the ink is in a piece of paper, and the
    // paper is what it is spreading through. It is kept far down the rail: this
    // is a hint that the substrate is there, not a second material.
    float Wh = W * 2.0;
    float hint = exp(-(n * n) / max(Wh * Wh, 1e-8))
               * smoothstep(-0.13 * S, 0.13 * S, (Lh + 0.14 * S) - u)
               * smoothstep(-0.16 * S, 0.16 * S, u + 0.34 * S);

    // The grain modulates the ink DEEPLY, 0.30 to 1.15 rather than the first
    // cut's 0.78 to 0.93. A shallow modulation is a texture on a solid shape; a
    // deep one is the shape.
    // THE SPINE. A feather's rachis: one bright line down the axis, brightest
    // at the head and thinning toward the tip, and the only part of this
    // species that reaches the rail's cream stop. It is what makes the plume
    // read as oriented at 20 pt, where the fibrous edge has become a soft
    // shoulder and the silhouette alone would be a smudge.
    float ws = 0.30 * Wref;
    float spine = exp(-(n * n) / max(ws * ws, 1e-8)) * front * back
                * (0.34 + 0.66 * (1.0 - 0.75 * uN));

    float dens = front * back * across * sat * (0.30 + 0.85 * fibre);
    float tv = 0.045 + 0.70 * clamp(dens, 0.0, 1.3)
             + (0.46 + 0.10 * bleed) * spine
             + (0.13 + 0.15 * dryness) * tip * across
             + 0.065 * hint * (0.30 + 0.70 * fibre);
    // SUCCESS: the stain drinks from the pen mark out to the reach, along the
    // grain, which is the same path the ink took getting there.
    tv += mi_drink(st, uN) * clamp(dens, 0.0, 1.3) * 0.26;

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

    float2 p = uv / S;

    // THE SURFACING FIELD. One tap, shared, and it is the only thing in this
    // shader with a clock. It both drifts and evolves: drifting alone sweeps a
    // wave across the page, evolving alone makes the same places breathe on a
    // timer, and neither on its own reads as memory. Together they mean a
    // different part of the sheet is giving something up every time you look.
    float srf = mi_fbm3(float3(p * 1.45 + float2(0.045, -0.032) * t, t * 0.085 + 5.0),
                        2, 2.03, 0.5);

    // The two hands trade places in the one surface. `layers` sharpens the trade:
    // at 0 they overlap almost everywhere and the page is one confused text, at 1
    // they separate into distinct territories.
    float sep = 0.10 + 0.26 * layers;
    float gate = smoothstep(-sep, sep, srf);
    // THE ENVELOPE, and the species does not work without it. The trade above
    // decides WHICH hand you are seeing, and by itself that is all it does: the
    // two visibilities sum to very nearly a constant, so every part of the page
    // carries the same amount of ink at all times and nothing ever appears to
    // rise or be taken back. The first cut had exactly that and read as a flat
    // busy texture rather than as memory. So a second, larger and slower field
    // decides HOW MUCH is up anywhere at all, and it drifts on its own heading
    // so the two mechanisms never fall into step. One raw octave: this is a
    // broad envelope and paying fBm for it would buy detail nobody can see.
    // The pitch is load bearing and the first number was wrong. At 0.95 the
    // whole indicator sits inside a single cell of this field, so the envelope
    // stops being a map of WHERE the page is giving something up and becomes one
    // number for the entire cell rising and falling: a brightness pulse, which
    // this family bans, and one that took the page to nearly black at its low
    // point. At 2.6 there are two or three regions across the disc at any
    // moment, so some part of the sheet is always surfaced while another is
    // being taken back, which is both the species and the reason the total never
    // goes away. The floor is 0.30 for the same reason halation's corona has one.
    // THE PAGE. The writing used to run to the edge of the cell, which makes it
    // a texture; a palimpsest is a SHEET, and a sheet has edges. An oval a
    // little wider than tall reads as a page at a glance and gives the species
    // the silhouette the figure law asks for, with ink ground around it. Soft
    // shouldered, because nothing in this family owns a hard edge.
    float pr = length(float2(p.x / 0.40, p.y / 0.27));
    float page = 1.0 - smoothstep(0.78, 1.06, pr);

    // THE SWEEP, and this is the motion-pass correction. The envelope used to
    // drift slowly and evolve quickly, and a field whose z runs faster than it
    // travels BOILS: patches brightened and dimmed where they stood, which is
    // flicker, not surfacing. Surfacing is a directional act. So the drift went
    // up by three and the evolution came down by half, and now a front of
    // legibility moves across the page: the writing comes up ahead of it and
    // goes back down behind, and you can point at which way it is going.
    // RESPONDING drives that front harder, which is this species answering.
    float2 sweep = float2(-0.140, 0.100) * (t * (1.0 + 1.5 * st.drive));
    float env = mi_noise3(float3(p * 2.6 + sweep, t * 0.030 + 19.0));
    float lift = 0.30 + 0.70 * smoothstep(-0.24, 0.30, env);

    // THE FLOURISH: one line surfaces closer to legible. A single band of the
    // page comes further up than the envelope was going to let it, holds for a
    // moment at the edge of being readable, and sinks again.
    //
    // It works the species' OWN coordinate rather than a brightness dial: `lift`
    // is the depth mechanism this whole shader is built on, so pushing one band
    // of it is the same operation the sheet performs everywhere else, just
    // locally and briefly. The band also sharpens the older hand where it
    // passes, which is the part that reads as legibility rather than as light,
    // and it is capped short of resolving because a palimpsest that finishes a
    // sentence has stopped being one.
    MIBeat gl = mi_beat(t, 89.0, 2.4, 0.30);
    float dyl = (p.y - (gl.id * 2.0 - 1.0) * 0.34) / 0.055;
    float ghost = gl.e * exp(-dyl * dyl);
    lift = min(1.0, lift + 0.55 * ghost);

    // Capped below 1, always. Reaching full density is what "resolving" would
    // mean and this species is defined by not getting there.
    float reach = (0.52 + 0.52 * surfacing) * lift;
    float visA = reach * gate;
    float visB = reach * (1.0 - gate) * (0.80 + 0.20 * layers);

    // The pixel footprint in page units, for the two places detail has to be
    // given up rather than aliased.
    float px = max(fwidth(p.x), 1e-5);
    float fine = 1.0 - smoothstep(0.012, 0.030, px);

    float writing = 0.0;
    for (int i = 0; i < 2; i++) {
        float fi = float(i);
        // The older hand is turned on the page and written smaller, which is what
        // a scraped and reused sheet actually looks like: nobody lines the new
        // text up with the old.
        float ha = 0.22 + fi * (0.55 + 0.90 * layers);
        float ca = cos(ha), sa2 = sin(ha);
        float2 e = float2(p.x * ca + p.y * sa2, -p.x * sa2 + p.y * ca);

        // THE ROWS. A wandering baseline, because a ruled one reads as a form to
        // fill in rather than as handwriting.
        // Three or four lines inside the page, not five across the whole cell:
        // the rhythm of ruled writing is the thing that says "a page of text"
        // before any mark is read, and it only reads if you can count them.
        float lineFreq = (6.4 + 3.0 * fi * (0.4 + 0.6 * layers)) / S;
        float yl = (e.y + 0.055 * sin(e.x * 2.3 + fi * 2.1)) * lineFreq;
        float wl = max(fwidth(yl), 1e-5);
        float attl = exp(-4.9348 * wl * wl);
        float row = 0.5 + 0.5 * cos(6.2831853 * yl) * attl;
        // The rows have to WIN. At a gentler exponent the strokes wandered
        // across the gaps and the page read as a scribble; ink between the lines
        // is the one thing that stops a sheet of writing looking like a thicket.
        row = pow(row, 2.4);

        // THE STROKES. Ridged noise, and the anisotropy is severe on purpose:
        // three to one across against along, so a mark is narrow enough to sit
        // inside one row instead of spanning three of them. A stroke taller than
        // its line is not handwriting, it is a fence.
        // Surfacing RISES. The marks are sampled a little further down the
        // field where the page is giving them up, so a stroke lifts within its
        // own line as it comes and settles back as it goes. It is a fiftieth of
        // a frame at most and it is the difference between a region getting
        // brighter and a region surfacing: one is a level, the other is an act
        // with a direction in it. The rows themselves do not move, so nothing
        // slides; only the ink comes up through the ruling.
        float sc = 1.0 - 0.28 * fi;
        float3 sp = float3(e.x * (16.0 * sc / S),
                           (e.y + 0.024 * lift) * (5.4 * sc / S), 11.0 + fi * 13.0);
        float ridge = saturate(1.0 - abs(mi_fbm3(sp, 2, 2.03, 0.5)) * (1.0 / 0.55));

        // Age erodes by SHARPENING. A higher exponent does not merely thin the
        // stroke, it breaks it wherever the ridge dips, which is exactly how
        // scraped ink fails: not evenly fainter, but in pieces.
        float aged = age * fi;                      // the second hand is the old one
        // The ghost line sharpens the OLDER hand as it passes, which is what
        // "closer to legible" means when nothing is allowed to become a letter.
        // RESPONDING sharpens the hand: answering is the page being clearer
        // about what it says, without ever being clear enough to read.
        float sharp = 1.8 + 4.6 * legibility + 3.2 * aged + 1.8 * ghost * fi
                    + 0.9 * st.drive;
        // At 20 pt a stroke this thin has nothing to stand on, so the exponent
        // relaxes toward the broad mass instead of aliasing into a strobe. The
        // page stops being readable before it starts being wrong.
        sharp = mix(1.5, sharp, fine);
        float stroke = pow(ridge, sharp) * row;

        writing += stroke * (i == 0 ? visA : visB);
    }

    // The tooth of the sheet. One raw octave, the cheapest thing in the file, and
    // it is here because a page with nothing on it between the writing is not a
    // page, it is a background.
    float tooth = mi_noise3(float3(p * (26.0 / S), 3.0));

    writing *= page;
    // The strokes are driven to the rail's cream stop at their most surfaced,
    // so the page has a top tier instead of topping out in rust. Everything
    // below them still falls back through amber into the ink of the sheet.
    // 2.05 and not the 1.24 the first pass used. A stroke here is the product
    // of two separately peaked functions, the ridge crest and the centre of its
    // line, and the two rarely peak at the same pixel: the field's realistic
    // maximum is under half of its arithmetic one, so a coefficient set from
    // the arithmetic maximum leaves the whole page in rust. This is set from
    // what the field ACTUALLY reaches, which puts the crest of a well surfaced
    // stroke at the rail's cream stop and everything less than that back down
    // through amber into the ink of the sheet.
    float tv = 0.048 + 2.05 * clamp(writing, 0.0, 1.2)
             + 0.045 * (0.5 + 0.5 * tooth) * page;
    // SUCCESS: the page takes up pigment line by line down the sheet, the way
    // it would have been written.
    tv += mi_drink(st, saturate(0.5 + p.y * 1.4)) * clamp(writing, 0.0, 1.2) * 0.30;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}
