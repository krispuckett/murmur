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
// it arrives. T is 1.9 s because the lab shoots its still frame at four
// seconds and four seconds is two time constants: R is at 94% of final, which
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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float spread = clamp(c0, 0.0, 1.0);
    float tearK  = clamp(c1, 0.0, 1.0);
    float tailK  = clamp(c2, 0.0, 1.0);
    float asym   = clamp(c3, 0.0, 1.0);

    // The law. One exponential, read twice.
    float tau = max(time - epoch, 0.0) * max(speed, 0.0);
    const float T = 1.9;
    float k = exp(-tau / T);                      // 1 at the drop, 0 arrived
    float Rinf = (0.19 + 0.15 * spread) * S;
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
    float ring = 0.8 + 1.0 * tearK;               // lobes around the front
    float fringe = mi_fbm3(float3(dir * ring, tau * 0.10 + 2.0), 2, 2.03, 0.5);
    float Rf = R * aniso * (1.0 + (0.10 + 0.42 * tearK) * fringe);

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
    float wr = max(0.62 * w, 0.008);
    float tide = exp(-(sd * sd) / (wr * wr));

    // The interior, creeping outward forever at a vanishing rate. It is a
    // DILATION of the domain and not a radial pullback: pulling the sample
    // radius back by a fixed distance folds the domain at that radius, and the
    // fold draws a ring and a pinched knot at the centre of the blot. Dividing
    // the whole plane instead stretches the texture as the blot grows, which is
    // both artefact-free and the truer statement: the paper's mottling is not
    // sliding under the ink, the wetted region is getting bigger.
    float2 mp = d2 / (S * (1.0 + 0.62 * R));
    float mott = mi_fbm3(float3(mp * 5.2, tau * 0.045 + 12.0), 3, 2.03, 0.5);

    // The interior sits mid-rail and the TIDE is the brightest thing in the
    // picture. That ordering is the difference between ink and fruit: a blot
    // whose middle is its highlight reads as a lit sphere, and the first cut of
    // this shader did exactly that.
    float dens = core * (0.62 + 0.26 * mott) + 0.45 * wash;
    float tv = 0.045 + 0.70 * clamp(dens, 0.0, 1.2)
             + (0.16 + 0.14 * tearK) * tide;

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
// the three phase rates (0.31, 0.22, 0.17 rad/s) are incommensurate, so the
// pattern never repeats and the eye never finds the cycle.
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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float folds    = clamp(c0, 0.0, 1.0);
    float comb     = clamp(c1, 0.0, 1.0);
    float contrast = clamp(c2, 0.0, 1.0);
    float driftK   = clamp(c3, 0.0, 1.0);

    float2 p = uv / S;
    // The sheet slides. Nine thousandths of a frame a second at the default:
    // over ten seconds that is a tenth of the picture, which is felt and not
    // watched, and it means the same fold never sits in the same place twice.
    p -= float2(0.86, 0.31) * (driftK * t * 0.035);

    float A = 0.050 + 0.075 * comb;
    p = mi_rake(p, float2( 0.9563,  0.2924),  7.3, A,         t * 0.31);
    p = mi_rake(p, float2(-0.4067,  0.9135), 12.9, A * 0.55, -t * 0.22 + 1.7);
    p = mi_rake(p, float2( 0.6691, -0.7431), 21.7, A * 0.26,  t * 0.17 + 4.1);

    // The sheet of ink the comb is drawn through. Broad: three octaves off a
    // base of 2.4 tops out around ten cycles a frame, which is structure a
    // 20 pt indicator can still hold.
    float sheet = mi_fbm3(float3(p * 2.4, t * 0.030 + 21.0), 3, 2.03, 0.5);

    // Band phase in CYCLES, built from the sheet plus a gentle lay direction so
    // the laminae have a grain to run along instead of closing into rings.
    float count = 1.0 + 2.2 * folds;
    float u = (sheet * 2.1 + dot(p, float2(0.2588, 0.9659)) * 1.35) * count;

    float wpx = max(fwidth(u), 1e-5);                  // cycles per device pixel
    float att = exp(-4.9348 * wpx * wpx);              // exp(-(pi w)^2 / 2)
    float s = 0.5 + 0.5 * cos(6.2831853 * u) * att;
    float body = pow(s, 1.0 + 2.4 * contrast);

    // Distance to the nearest band crest, in cycles, converted to PIXELS by the
    // same derivative. A vein is then about 1.7 px of half-width at every size,
    // which is what keeps a drawn line looking drawn at 300 pt and stops it
    // becoming a strobe at 20.
    float dpx = abs(fract(u + 0.5) - 0.5) / wpx;
    float vein = exp(-dpx * dpx / 2.9) * att;

    float mass = mix(saturate(0.5 + 0.85 * sheet), body, att);
    // The vein is the drawn line and the body is the ink it was drawn in, and
    // the body has to win. Weighted the other way the picture is hairlines on
    // black, which is a lightning storm rather than a bath of ink.
    float tv = 0.055 + 0.62 * mass + (0.07 + 0.13 * contrast) * vein;

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
// standing front at three hundredths of a frame a second. The front has
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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    // Up is +y here and nowhere else in this file. This style is ABOUT the
    // direction, so it gets to own the sign.
    float2 q = float2(uv.x, -uv.y);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float climb   = clamp(c0, 0.0, 1.0);
    float fiber   = clamp(c1, 0.0, 1.0);
    float pooling = clamp(c2, 0.0, 1.0);
    float dry     = clamp(c3, 0.0, 1.0);

    // Jurin: the equilibrium height, and the spread of it across the sheet.
    float h0 = -0.19 + 0.42 * climb;
    float rag = mi_fbm3(float3(q.x * (5.5 / S), 0.0, t * 0.075 + 4.0), 3, 2.03, 0.5);
    float front = h0 + (0.050 + 0.100 * fiber) * rag;

    float sd = front - q.y;                        // > 0 wet
    float wEdge = 0.030 - 0.018 * dry;
    float wet = smoothstep(-wEdge, wEdge, sd);

    // The tooth of the paper: high frequency across the fibres, low along them,
    // which is what makes the texture read as fibre rather than as noise. The
    // ratio is the whole effect and it wants to be severe, about seven to one;
    // at two to one the climb is mottled rather than striated, which is what
    // the first cut looked like and it could have been any of the other five.
    // The y term carries the transport.
    float3 gp = float3(q.x * (15.0 / S), (q.y - t * 0.030) * (2.2 / S), 9.0);
    float grain = mi_fbm3(gp, 2, 2.03, 0.55);

    // The concentration gradient a chromatogram has: strong at the source,
    // exhausted at the front.
    float conc = mix(0.52, 1.0, saturate(sd / 0.42));

    float wr = 0.010 + 0.026 * (1.0 - dry);
    float tide = exp(-(sd * sd) / (wr * wr));

    // The foot of the sheet stands in the reservoir.
    float src = 1.0 - smoothstep(-0.42, -0.12, q.y);

    float dens = wet * conc * (0.80 + 0.85 * fiber * grain) + pooling * 0.42 * src;
    float tv = 0.045 + 0.64 * clamp(dens, 0.0, 1.3)
             + (0.14 + 0.18 * dry) * tide
             // Dry paper is not blank paper. A whisper of tooth above the line
             // is most of what makes this interesting at 300 pt and it costs
             // nothing: the grain tap is already paid for.
             + 0.050 * (1.0 - wet) * (0.5 + 0.5 * grain);

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
//   c1 settle     how quickly the suspension arrives (T, 2.4 s at the default)
//   c2 disturb    residual convection in the boundaries
//   c3 tilt       which way the vessel leans, 0.5 being level
[[ stitchable ]] half4 mi_strata(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float layers  = clamp(c0, 0.0, 1.0);
    float settle  = clamp(c1, 0.0, 1.0);
    float disturb = clamp(c2, 0.0, 1.0);
    float tiltK   = clamp(c3, 0.0, 1.0);

    float tau = max(time - epoch, 0.0) * max(speed, 0.0);
    float T = 2.4 / (0.55 + 0.90 * settle);
    float k = exp(-tau / T);                       // 1 suspended, 0 settled
    float clear = 1.0 - k;

    // The lean, plus the rock the vessel never loses.
    float ang = (tiltK - 0.5) * 0.40 + 0.035 * sin(t * 0.17) + 0.022 * sin(t * 0.104 + 2.1);
    float ca = cos(ang), sa = sin(ang);
    float xAc =  uv.x * ca + (-uv.y) * sa;
    float yUp = -uv.x * sa + (-uv.y) * ca;

    float rip = mi_fbm3(float3(uv * (2.6 / S), t * 0.085 + 31.0), 2, 2.03, 0.5);
    float y = yUp + disturb * 0.045 * rip;

    // The anisotropy the arc drives. At k = 1 both axes sit at 5.6, which is a
    // cloud; at k = 0 the horizontal has fallen to 2.2 and the vertical has
    // climbed past ten, which is a bed.
    float fx = mix(2.2, 5.6, k) / S;
    float fy = mix(6.5 + 7.5 * layers, 5.6, k) / S;
    float n = mi_fbm3(float3(xAc * fx, y * fy, tau * 0.030 + 3.0), 2, 2.03, 0.5);
    // Beds have edges. 1.55 rather than 1.15 is what separates one lamina from
    // the next instead of leaving a smear that could be any horizontal field.
    float dens = saturate(0.50 + 1.55 * n);

    float bed = 1.0 - smoothstep(-0.22, 0.24, y);   // 1 low, 0 high
    float env = mix(0.85, mix(0.16, 1.0, bed), clear);

    // Compaction: the bottom of a settled bed carries more than its share,
    // because everything above it is pressing down on it.
    float tv = 0.045 + 0.62 * dens * env + 0.10 * bed * clear * dens;

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
// The mass reforms and also DRIFTS, slowly, about a hundredth of a frame a
// second. A mass that only morphs in place reads as a lava lamp on a timer.
//
//   c0 mass       the threshold: how much of the frame the dark body occupies
//   c1 corona     the width and strength of the scatter
//   c2 morph      how fast the body reforms
//   c3 offset     the direction the light comes from, in turns
[[ stitchable ]] half4 mi_halation(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float massK  = clamp(c0, 0.0, 1.0);
    float corona = clamp(c1, 0.0, 1.0);
    float morph  = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // 1.8 cycles a frame, not 2.3: at the higher pitch the level set breaks
    // into four or five separate islands and the picture is a maze of lit
    // edges, which is not a mass wearing light. One body with two or three
    // lobes is the whole subject, and the pitch is what decides it.
    const float F = 1.8;                            // domain scale, cycles a frame
    float2 p = uv / S;
    float3 q = float3(p * F + float2(0.020, -0.014) * t,
                      t * (0.020 + 0.055 * morph) + 6.0);
    float4 Fd = mi_fbmd3(q, 3, 2.03, 0.5);
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
    const float B = 4.5;
    float f = 0.42 + 0.55 * Fd.x - B * dot(uv, uv);
    // The chain rule, and it is not optional: the gradient comes back in the
    // noise domain, and a distance measured there is not a distance on screen.
    // The well's own gradient is carried with it, or the distance estimate is
    // wrong by exactly the term that makes the body a body.
    float2 g = 0.55 * Fd.yz * (F / S) - 2.0 * B * uv;
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
    float wr = 0.005 + 0.013 * corona;
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
             + (0.09 + 0.10 * corona) * rim  * (0.55 + 0.45 * facing);

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
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = mi_uv(position, size);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
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
    // moving through the third coordinate at a fiftieth of a cycle a second:
    // slower than anything else in this file, which is the point of the style.
    float rimN = mi_fbm3(float3(dir * 1.35, t * 0.020 + 17.0), 2, 2.03, 0.5);
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
    const float SF = 3.1;
    float4 Sf = mi_fbmd3(float3(uv * (SF / S), t * (0.030 + 0.070 * tremor) + 41.0),
                         3, 2.03, 0.5);
    float2 slope = Sf.yz * (SF / S) * (0.024 + 0.060 * tremor);

    // The shore, anti-aliased by the same derivative the marbling uses, so the
    // edge of the pool is one pixel at 20 pt and one pixel at 300 pt.
    float e = max(fwidth(rr), 1e-5);
    float pool = 1.0 - smoothstep(R - e, R + e, rr);

    // Jurin from the other side: the liquid climbs the wall over its capillary
    // length, and that climb tips the surface outward.
    float lambda = (0.008 + 0.024 * tension) * S;
    float men = exp(-max(R - rr, 0.0) / lambda) * pool;
    // Almost all of the meniscus goes into the SLOPE and only a little into the
    // brightness, and that split is the whole reason this shader is allowed to
    // have a rim at all. Light added directly at the wall paints a ring, and a
    // ring is a drawn circle. Tipping the surface there instead lets the same
    // overhead light decide: the wall catches a bright ARC where it faces the
    // source and stays dark where it turns away, which is what a dish of ink on
    // a table actually looks like and is not a shape anybody drew.
    slope += dir * (men * (0.34 + 0.40 * tension));

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
             + (0.10 + 0.12 * tension) * men
             + 0.075 * dried;

    MIPalette pal = mi_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mi_srgb_to_linear(float3(inkColor.rgb));
    return mi_finish(mi_shade(pal, tv), inkLin, mi_shore(uv), glow, position * pixelScale);
}
