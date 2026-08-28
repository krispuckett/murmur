// The Light pack. Six thinking indicators made of light that has been THROUGH
// something before it reaches the eye: water, air, fog, dust, heat. The Liquid
// pack has the pour's weight and the Ink pack has paper's capillary time; this
// family's subject is a medium, and the medium is what moves.
//
//   mg_caustic  the fold of a caustic on a pool floor: a soft web, drawn as the
//               zero set of the ray map's Jacobian, never as cells.
//   mg_aurora   a curtain of light folded in slow air. Hard lower border, soft
//               top, brightness where the folds overlap. Nothing falls.
//   mg_ember    the air above a warm floor: light pooled low, the coals seen
//               through their own rising shimmer.
//   mg_lantern  one lamp of CONSTANT brightness behind drifting fog. What moves
//               is the fog, and the shadows it throws across its own light.
//   mg_mirage   the desert road: layered air bending a distant light, folded
//               below the inversion into its own mirrored second image.
//   mg_oculus   an aperture admitting light, opening as the thought completes.
//               Open is the rest state, and rest is not a freeze.
//
// THE FAMILY LAW, and every one of these obeys it. Time enters where a
// COORDINATE IS READ, never as a brightness multiplier. That is not a style
// preference here, it is the whole difference between a lantern and a novelty
// lamp: mg_lantern's source is exactly as bright at t = 300 as it was at t = 0,
// and the picture is alive anyway because the medium in front of it is not
// where it was. A light that throbs is the failure mode this family is most
// exposed to, so none of the six modulates emission with time at all. Check any
// of them by deleting `time` from the field and looking at what stops: it must
// be the medium, never the light.
//
// THE SCALE CONSTRAINT, which is new to this pack and governs every frequency
// below. These are indicators, drawn at 46 pt in a chat row and at 300 pt on a
// design surface, and the uv frame here is normalised so ONE UV UNIT IS THE
// SHORT SIDE. At 46 pt that means a noise cell of 0.06 uv is under three
// points across. Anything finer sparkles instead of drifting, which is the
// opposite of calm and is also what aliases first. So the rule the numbers here
// are picked against: the FINEST octave's cell stays at or above ~0.06 uv.
// With the kit's 2.03 lacunarity that caps a three octave field near f = 4 and
// a two octave field near f = 8, and where a frequency below sits at the top of
// its range the comment says which octave count is holding it there.
//
// THE CONTAINMENT. The view clips to a circle. A clip that lands on lit pixels
// draws a hard rim, and a hard rim on an organic form is the one edge this
// house never ships, so every style brings its light down to pure ink well
// inside length(uv) = 0.5 through mg_hold before the clip is ever consulted.
// The clip should have nothing left to cut.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal VERBATIM under an mg_
// prefix, the way the house has done it before. Copied, unchanged except for
// the name:
//
//   mg_hash, mg_grad3, mg_noised3, mg_noise3, MG_ROT, mg_fbmd3, mg_fbm3,
//   mg_srgb_to_linear, mg_linear_to_srgb, mg_linear_to_oklab,
//   mg_oklab_to_linear, mg_lch, MGPalette, mg_palette, mg_shade, mg_out,
//   mg_knee, mg_hash1, mg_vnoise1, mg_fbm1
//
// Their comments come with them: the reasoning is the part worth carrying.
// mg_hold is the one helper written rather than copied, and it says why.
// Nothing here is behind the prefix that the six styles do not call.
//
// A NOTE ON THE NUMBERS, in the pour's spirit of saying which is which. The
// pour's constants were fitted against a photograph of the shipped card. These
// were not: they are reasoned from the octave weights, the uv scale above, and
// what each medium actually does, and the reviewing session's screenshots are
// the first time any of them meets an eye. Where a constant is the one to move
// if the picture disagrees, the comment names it.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's, verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mg_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mg_grad3(int3 c) {
    uint h = mg_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// Gradient noise and its analytic gradient, in one evaluation.
/// Returns (value, d/dx, d/dy, d/dz). Quintic interpolation, so the derivative
/// is itself continuous: lighting built on it has no facets at cell walls.
static float4 mg_noised3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
    int3 c = int3(i);

    float3 ga = mg_grad3(c + int3(0, 0, 0));
    float3 gb = mg_grad3(c + int3(1, 0, 0));
    float3 gc = mg_grad3(c + int3(0, 1, 0));
    float3 gd = mg_grad3(c + int3(1, 1, 0));
    float3 ge = mg_grad3(c + int3(0, 0, 1));
    float3 gf = mg_grad3(c + int3(1, 0, 1));
    float3 gg = mg_grad3(c + int3(0, 1, 1));
    float3 gh = mg_grad3(c + int3(1, 1, 1));

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
static float mg_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mg_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mg_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mg_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mg_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mg_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mg_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mg_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mg_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse, which
/// is exactly what the chain rule below needs. Without it every octave stacks on
/// the same lattice axes and the field grows a visible plaid.
constant float3x3 MG_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

/// fBm carrying its own derivative. `mt` accumulates the transpose of the map
/// from the base domain to the current octave's domain, so each octave's
/// gradient is rotated back before it is summed. Returns (value, gradient).
static float4 mg_fbmd3(float3 p, int octaves, float lacunarity, float gain) {
    float3x3 rotT = transpose(MG_ROT);
    float3x3 mt = float3x3(1.0);
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    float3 grad = float3(0.0);
    for (int i = 0; i < octaves; i++) {
        float4 n = mg_noised3(q);
        value += amp * n.x;
        grad += amp * (mt * n.yzw);
        amp *= gain;
        q = lacunarity * (MG_ROT * q);
        mt = lacunarity * (mt * rotT);
    }
    return float4(value, grad);
}

static float mg_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * mg_noise3(q);
        amp *= gain;
        q = lacunarity * (MG_ROT * q);
    }
    return value;
}

static inline float3 mg_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mg_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mg_linear_to_oklab(float3 c) {
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

static inline float3 mg_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mg_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the day tone the ribbon wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MGPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MGPalette mg_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mg_linear_to_oklab(mg_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mg_linear_to_oklab(mg_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MGPalette p;
    p.s0 = ink;
    p.s1 = mg_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mg_lch(L, C, h);
    p.s3 = mg_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mg_out does the encoding.
static float3 mg_shade(MGPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return mg_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mg_out(float3 linearRGB, float2 pixel) {
    float3 c = mg_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mg_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

static inline float mg_hash1(float cell, float lane) {
    return float(mg_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float mg_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mg_hash1(i, lane), mg_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float mg_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * mg_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

// MARK: - The circle
//
// The one helper written rather than copied, and it replaces fl_edge for a
// reason worth stating.

/// The circle's own edge law. FieldLab's fl_edge fades a field toward a
/// rectangular frame in a 0...1 uv, and neither half of that is true here: the
/// frame is a CIRCLE, the uv is centred at zero, and the view puts a hard
/// clipShape on the result. A clip is not a fade. If any light is still lit
/// where the clip lands, the indicator grows a crisp circular rim, and a crisp
/// rim on an organic form is the one edge this house does not ship.
///
/// So r is measured against the clip radius (1.0 is exactly where the clip
/// falls) and everything is gone before 0.94 of it: at 46 pt that leaves about
/// a point and a half of pure ink for the antialiased clip edge to land in, and
/// at 300 pt it leaves nine. `reach` is clamped rather than trusted, because a
/// style that wanted a wider field would otherwise be able to hand the clip
/// something to cut, and no style is allowed to make that mistake.
static inline float mg_hold(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    float a = clamp(reach, 0.30, 0.64);
    return 1.0 - smoothstep(a, a + 0.30, r);
}

// MARK: - 1. Caustic

// CAUSTIC. Light refracted through moving water, landing on a floor.
//
// The web is the whole species, and the honest question is what a caustic web
// actually IS. It is not a cell pattern, which is why every Voronoi version of
// this reads as a lie: it is the FOLD of the map that carries rays from the
// water surface to the floor. Take a surface height h, refract, and every point
// of the surface sends its ray to
//
//     floor(p) = p - k grad h(p)
//
// The floor's brightness at a point is the number of rays that land in a unit
// area there, which is one over the determinant of that map's Jacobian:
//
//     J = I - k H,      H = the Hessian of h
//     det J = (1 - k Hxx)(1 - k Hyy) - k^2 Hxy^2
//
// Where det J crosses zero, an area of surface collapses onto a curve of floor
// and the light there is unbounded. That curve family, smooth and wandering and
// closing on itself, IS the web. It is drawn here as w / (w + |det J|), which is
// the same shape as 1/|det| with a width instead of an infinity, so the threads
// are soft at every scale and there is no exposure at which they blow out.
//
// The Hessian costs two extra taps and no finite differencing of the VALUE,
// because the kit's mg_fbmd3 already returns the analytic gradient: differencing
// the gradient once gives the second derivative for the price of two more field
// evaluations instead of the eight a value-space Hessian would need. That is the
// derivative in the kit finally earning its keep. Six taps total.
//
// TWO OCTAVES, and this one is physics rather than budget. A water surface is
// smooth: capillary detail exists but it does not focus, and adding octaves here
// puts the Hessian's energy in the top octave, which fills the frame with tiny
// closed loops and lands exactly on the cellular reading this species must never
// have. Two octaves keeps the folds broad and the web legible at 20 pt.
//
// THE NUMBER TO MOVE. `k` below is the focusing strength, and it is reasoned
// rather than photographed: the fBm's second-derivative gain over its base
// octave is 0.5 + 0.25 * 2.03^2 = 1.53, the base octave's own curvature runs
// around 4, so H sits near 6 typical and k near 0.16 puts k H at about 1, which
// is where folds start forming. If the web comes out sparse, raise the 0.20; if
// it comes out busy, lower it. Nothing else in this style needs to move.
//
//   c0 web     how much surface there is across the frame: fewer, broader folds
//              to more of them.
//   c1 depth   how far the floor is below the surface. Deeper water focuses
//              harder, so this is literally k.
//   c2 swim    NOT a second speed dial. It sets how much of the motion is the
//              water body TRAVELLING across the floor versus reorganising in
//              place. At 0 the web churns without going anywhere; at 1 it
//              drifts, and the drift is what makes a small indicator read as
//              current rather than as boiling.
//   c3 focus   thread width. Broad soft glow to a tight bright filigree.
[[ stitchable ]] half4 mg_caustic(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));                    // the pour's own guard
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float web = clamp(c0, 0.0, 1.0);
    float deepK = clamp(c1, 0.0, 1.0);
    float swim = clamp(c2, 0.0, 1.0);
    float focus = clamp(c3, 0.0, 1.0);

    // The surface domain. f = 4.8 at the default; two octaves puts the finest
    // cell at 1/(4.8 * 2.03) = 0.10 uv, which is five points at 46 pt: broad
    // enough to drift, coarse enough never to sparkle.
    float f = (3.2 + 3.2 * web) / S;
    // The two motions, and they are different things. The drift is the body of
    // water moving over the floor and it carries the whole pattern with it. The
    // churn is the third noise axis, which reorganises the surface without
    // translating it. `swim` trades between them; neither is ever zero, because
    // still water is not this species.
    float2 drift = float2(0.052, 0.019) * t * (0.30 + 1.55 * swim);
    float churn = t * (0.155 - 0.055 * swim);
    float3 p = float3((uv + drift) * f, churn);

    // The Hessian, by differencing the analytic gradient. e = 0.10 of a cell is
    // small enough to be a second derivative and large enough to low pass the
    // very top of the octave stack, which is the same softening a real lens
    // aperture does to a caustic.
    const float e = 0.10;
    float4 s0 = mg_fbmd3(p, 2, 2.03, 0.5);
    float4 sx = mg_fbmd3(p + float3(e, 0.0, 0.0), 2, 2.03, 0.5);
    float4 sy = mg_fbmd3(p + float3(0.0, e, 0.0), 2, 2.03, 0.5);
    float inv = 1.0 / e;
    float hxx = (sx.y - s0.y) * inv;
    float hxy = (sx.z - s0.z) * inv;
    float hyy = (sy.z - s0.z) * inv;

    float k = 0.06 + 0.20 * deepK;
    float det = (1.0 - k * hxx) * (1.0 - k * hyy) - k * k * hxy * hxy;

    // The fold, with a width instead of a singularity. Bounded in (0, 1] by
    // construction, so a badly tuned k cannot produce a white frame: too little
    // focusing gives a dim even wash, too much gives a busy one, and neither
    // clips.
    float w = 0.42 - 0.30 * focus;
    float fold = w / (w + abs(det));
    fold = pow(fold, 1.0 + 0.9 * focus);

    // The floor is not black between the threads. It is lit by the same light,
    // just unfocused, and the surface's own thickness modulates how much gets
    // through. Costs nothing: s0.x is already in hand.
    float ambient = 0.115 + 0.085 * (0.5 + 0.5 * s0.x);
    float lit = ambient + (0.44 + 0.16 * deepK) * fold;

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.88));
    // The emission colour is taken NEAR THE TONE and not at the rail's pale
    // stop. The pour learned this the expensive way: once the knee has
    // saturated red and green, a pale stop takes blue up with them and warm
    // metal turns white. Sitting the emission at 0.80 lets the knee make its
    // own yellow out of the tone instead.
    float3 em = mg_shade(pal, 0.80) * (0.42 * pow(fold, 3.2)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 2. Aurora

// AURORA. A curtain of light folded in slow air.
//
// The grammar is horizontal and nothing falls, which is the whole distance
// between this and the Liquid pack. What an aurora is, physically, is a SHEET
// seen edge on: brightness is path length through the sheet, so where the sheet
// folds back across itself the light doubles, and that doubling is the only
// place a curtain ever gets bright. There is no emission dial in this style at
// all beyond the house one, because the brightening is geometry.
//
// Two facts about a real curtain carry most of the reading, and both are in the
// vertical profile:
//
//   the lower border is SHARP. It is where the incoming particles finally run
//   out of atmosphere to hit, and it is the crispest edge in the sky.
//   the top is DIFFUSE. It fades over kilometres with nothing to end it.
//
// So the profile is a fast smoothstep up into the foot and an exponential decay
// above it. Invert those two and the thing reads as fog, which is what the first
// sketch of every aurora shader does.
//
// THREE LAMINAE, feet 0.03 uv apart, each wandering on its own pair of 1D fBm
// lanes at its own rate. They are not three curtains: they are one sheet seen
// where it folds, which is why their feet sit so close together and why their
// sum is allowed to exceed one. Where two cross, the light doubles, and the
// bright vertical concentrations that appear and slide are the folds. On a line
// this costs two hashes an octave rather than the thirty two a 3D lattice would,
// which is what makes three of them affordable at 300 pt.
//
// The rays are one octave of value noise, not fBm, and that is deliberate. Two
// octaves put ray structure under three points at 46 pt and it sparkled. One
// quintic octave is a soft undulation in the curtain's brightness, which is what
// rays look like when you are not standing under them. They lean with height,
// because a curtain's rays follow the field lines and the field lines are not
// vertical in the picture plane.
//
//   c0 fold    how far the sheet wanders vertically. Low is a calm band, high
//              is a curtain with real folds in it.
//   c1 height  the exponential scale of the top's fade. How much of the frame
//              the curtain occupies above its foot.
//   c2 wander  how fast the folds travel. The three laminae drift at different
//              rates by construction, so this never reads as one sliding image.
//   c3 thin    the sheet's cross section. High is a defined lower border and a
//              compact curtain; low is a soft aurora seen through cloud.
[[ stitchable ]] half4 mg_aurora(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float foldK = clamp(c0, 0.0, 1.0);
    float heightK = clamp(c1, 0.0, 1.0);
    float wander = clamp(c2, 0.0, 1.0);
    float thin = clamp(c3, 0.0, 1.0);

    // The sky's frame. uv.y runs down the screen, so up is negative; `up` is
    // measured the way the curtain is built, which is from its foot.
    float x = uv.x / S;
    float up = -uv.y / S;

    // The top's fade, and the lower border's softness. `thin` runs the border
    // from 0.078 uv (a soft aurora behind cloud) to 0.020 (the crisp lower edge
    // a clear night gives), and 0.020 is still four soft points at 46 pt: sharp
    // for this family, never an edge.
    float H = 0.09 + 0.22 * heightK;
    float border = 0.078 - 0.058 * thin;

    float sheet = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float lane = 4.0 + 13.0 * fi;
        // Each lamina drifts at its own rate, and the two fBm terms inside it
        // travel in OPPOSITE directions. That is the difference between a fold
        // and a slide: two counter-moving components sum to a shape that
        // changes, while one component only translates.
        float rate = (0.055 + 0.115 * wander) * (1.0 + 0.42 * fi);
        float big = mg_fbm1(x * 3.4 + t * rate, 2, lane) * 0.115;
        float fine = mg_fbm1(x * 7.5 - t * rate * 0.63, 2, lane + 7.0) * 0.030;
        float foot = 0.050 + 0.030 * fi + (big + fine) * (0.35 + 1.30 * foldK);

        float h = up - foot;
        // Sharp below, diffuse above. Reverse these two and the species is fog.
        float prof = smoothstep(-border, 0.0, h) * exp(-max(h, 0.0) / H);

        // The rays. One quintic octave, leaning with height, drifting slowly.
        float ray = 0.74 + 0.26 * (0.5 + 0.5 * mg_vnoise1(x * 5.2 + h * 1.15 + t * rate * 0.8,
                                                          lane + 23.0));
        // The far laminae are dimmer, the way the far side of a fold is.
        sheet += prof * ray * (1.0 - 0.24 * fi);
    }

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    // The sky is not empty above the curtain: airglow, at the bottom of the
    // rail, so the disc never goes to a dead flat ink where the sheet is not.
    float lit = 0.055 + 0.52 * sheet;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    // Only the overlaps emit. sheet passes 1.0 where two laminae cross, and the
    // cube makes that crossing the only thing on screen that glows.
    float3 em = mg_shade(pal, 0.80) * (0.30 * pow(max(sheet - 0.55, 0.0), 2.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.58));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 3. Ember

// EMBER. The air above a warm floor.
//
// The trap in this species is the obvious one: coals that breathe. A glow that
// swells and fades is the first thing anyone writes here and it is exactly the
// pulsing luminance the family forbids, so the coals in this shader have a
// brightness that does not depend on `time` at ALL. What moves is the air, and
// the air moves in three ways that are each a coordinate being read differently:
//
//   the shimmer   hot air refracts, so the sightline bends. The bed and the
//                 plume are both sampled at x + dx where dx is a slow field
//                 growing with height, because there is no bending in the first
//                 millimetre above a floor and plenty of it higher up. The
//                 coals appear to swim; the coals do not move.
//   the rise      the plume's domain scrolls DOWN in height as t grows, which
//                 carries its structure up. This is the Liquid pack's fall
//                 inverted, and it is the only place in the Light pack where
//                 the vertical motion is the subject.
//   the spread    a buoyant plume widens as it climbs, so the horizontal
//                 frequency is divided by (1 + spread h). Without it the column
//                 reads as a scrolling texture in a box rather than as gas
//                 leaving a fire.
//
// The bed is a FIELD and not a ramp: patches of noise confined near the floor
// line by an exponential, so some coals are hot and some are not, the way a bed
// of embers actually looks. A vertical gradient dimmed at the top would have
// been half the code and would have failed the first rule in the spec.
//
//   c0 heat      how far the column carries. This is the plume's exponential
//                reach, so it is the difference between a low bed of coals and
//                a fire with a real thermal above it.
//   c1 shimmer   refraction amplitude. The single most legible dial at 20 pt.
//   c2 floor     where the floor sits in the circle and how thick the bed is.
//   c3 updraft   how fast the air leaves and how vertically stretched it gets
//                on the way. Fast and stretched reads as a draught; slow and
//                compact reads as still air over dying coals.
[[ stitchable ]] half4 mg_ember(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float heat = clamp(c0, 0.0, 1.0);
    float shimmer = clamp(c1, 0.0, 1.0);
    float floorK = clamp(c2, 0.0, 1.0);
    float updraft = clamp(c3, 0.0, 1.0);

    // The floor sits low in the circle. uv.y runs down, so a pixel above the
    // floor has a smaller y and a positive height.
    float floorY = 0.16 + 0.12 * floorK;
    float x = uv.x / S;
    float h = (floorY - uv.y) / S;

    // THE SHIMMER. Two octaves at f = 2.1 is a broad, slow warp: fine warp
    // detail here would tear the coals into speckle instead of making them swim.
    // It grows from nothing at the floor, because air that has not risen yet has
    // not had time to bend anything.
    float3 wp = float3(x * 2.1, h * 1.7 - t * (0.30 + 0.52 * updraft), t * 0.20);
    float warp = mg_fbm3(wp, 2, 2.03, 0.5);
    float dx = warp * (0.030 + 0.080 * shimmer) * smoothstep(0.0, 0.32, h);
    float xs = x + dx;

    // THE BED. Patches, not a ramp. Its own slow crawl in the third axis is the
    // coals shifting as they burn down, and it is the only motion the light
    // itself has: about a fortieth of the plume's rate, which is felt and not
    // watched.
    float3 bp = float3(xs * 2.8, 0.0, t * 0.075);
    float bed = 0.5 + 0.5 * mg_fbm3(bp, 3, 2.03, 0.5);
    float bedThick = 0.050 + 0.060 * floorK;
    float bedMask = smoothstep(-0.085, -0.004, h) * exp(-max(h, 0.0) / bedThick);

    // THE PLUME. Domain scrolls down so structure travels up; horizontal
    // frequency opens with height so the column widens as it climbs.
    float spread = 1.0 + (0.85 + 1.55 * updraft) * max(h, 0.0);
    float3 pp = float3(xs * (2.6 / spread),
                       h * (2.30 - 0.80 * updraft) - t * (0.52 + 0.86 * updraft),
                       t * 0.13);
    float plume = 0.5 + 0.5 * mg_fbm3(pp, 3, 2.03, 0.5);
    float column = exp(-max(h, 0.0) / (0.16 + 0.40 * heat));
    // Only the hot part of the plume carries light. The smoothstep is what turns
    // a uniform column of noise into separate tongues of warm gas.
    float rise = column * smoothstep(0.32, 0.86, plume);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float coals = bedMask * (0.30 + 0.62 * bed);
    float lit = 0.045 + 0.86 * coals + (0.20 + 0.34 * heat) * rise;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    // Only the coals themselves emit. Gas glowing as hard as the fuel is what
    // makes a fire shader read as a cartoon.
    float3 em = mg_shade(pal, 0.80) * (0.55 * pow(coals, 2.6)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.58));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 4. Lantern

// LANTERN. One light behind moving fog.
//
// This is the style the family law was written for, so it is worth being exact.
// The lamp's power is a CONSTANT. It appears in the code once, it is never
// multiplied by anything derived from `time`, and if the fog were removed the
// picture would be a still image. Every bit of life on screen comes from the
// medium sliding in front of the light. A lantern that throbs is a novelty; a
// lantern whose fog is moving is a lantern.
//
// The model is single scattering, which is the honest one and also the cheap
// one. The eye sees the fog AT the pixel, lit by the lamp, dimmed by whatever
// fog stands between:
//
//     L(p) = rho(p) * Lamp(|p - lamp|) * exp(-ext * integral of rho from lamp to p)
//
// The integral is four samples along the line from the pixel toward the lamp,
// which with the pixel's own density is five field taps and the whole budget of
// this style. What that integral buys is the thing that makes the picture: a
// thick wisp standing between the lamp and one side of the frame throws a soft
// SHADOW across it, and as the fog drifts those shadows sweep. Nothing in the
// frame is drawn as a ray and there is not a single hard edge anywhere, and yet
// the light visibly comes from a place.
//
// The lamp is never drawn. There is no disc, no core, no falloff sprite: the
// brightest pixel on screen is bright because the fog is dense THERE, so the
// centre of the glow wears the fog's own shape and can never resolve into an
// orb. Watch the middle of it drift off round as a wisp crosses. That is the
// species.
//
// The fog domain is compressed 2.2x across, because fog in still air lies in
// horizontal sheets, and the anisotropy is a second reason the halo never comes
// out circular.
//
//   c0 fog     density and extinction together. Low is a clear night with a
//              lamp a long way off; high is weather, where the light barely
//              gets out of its own halo.
//   c1 reach   how far the light carries: the softening radius of the inverse
//              square. This is also the dial that decides whether the indicator
//              reads as one presence or as a lit field.
//   c2 drift   how fast the fog crosses and turns over.
//   c3 offset  how far the lamp sits off centre. At 0 it is dead centre, which
//              is the least interesting composition and is not the default.
[[ stitchable ]] half4 mg_lantern(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float fogK = clamp(c0, 0.0, 1.0);
    float reach = clamp(c1, 0.0, 1.0);
    float driftK = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // The lamp. Up and to the left, because a light source placed on the
    // diagonal reads as a place in a room and a centred one reads as a target.
    // Its position does not scale with formScale: it is a location, not a form.
    float2 lamp = float2(-0.155, -0.115) * offset;

    // The fog. Sheets, so the domain is compressed across. Two octaves at
    // f = 5.2 puts the finest cell at 0.095 uv, four points at 46 pt.
    float2 flow = float2(0.072, -0.026) * t * (0.32 + 1.30 * driftK);
    float ff = 5.2 / S;
    float fz = t * (0.045 + 0.150 * driftK);

    // The pixel's own density: this is what the eye is actually looking at.
    float2 q0 = (uv + flow) * float2(ff / 2.2, ff);
    float d0 = 0.5 + 0.5 * mg_fbm3(float3(q0, fz), 2, 2.03, 0.5);
    d0 = pow(d0, 1.15) * (0.30 + 1.45 * fogK);

    // The occlusion between the lamp and here. Four samples, trapezoid-ish, and
    // the fixed count is the point: the loop bound never depends on the distance
    // to the lamp, so a pixel in the corner costs exactly what a pixel at the
    // centre costs.
    float2 ray = lamp - uv;
    float len = length(ray);
    float tau = 0.0;
    for (int i = 1; i <= 4; i++) {
        float s = (float(i) - 0.5) * 0.25;
        float2 q = (uv + ray * s + flow) * float2(ff / 2.2, ff);
        float d = 0.5 + 0.5 * mg_fbm3(float3(q, fz), 2, 2.03, 0.5);
        tau += pow(d, 1.15) * (0.30 + 1.45 * fogK);
    }
    tau *= len * 0.25;
    float shade = exp(-tau * (2.6 + 7.0 * fogK));

    // THE LAMP'S POWER, and this is the constant the whole style rests on. The
    // softening radius keeps the inverse square finite at the source, and it is
    // generous on purpose: a tight core would resolve into the orb this family
    // bans, and a broad one leaves the fog's own structure as the only thing
    // shaping the middle of the glow.
    float sig = (0.075 + 0.150 * reach) * S;
    float dist2 = dot(uv - lamp, uv - lamp);
    float lampL = (sig * sig) / (dist2 + sig * sig);

    // What the eye sees. The second term is the multiply-scattered haze that
    // survives even where the direct path is blocked, without which the
    // shadows read as holes cut in the picture rather than as shadow.
    float lit = d0 * lampL * (0.20 + 0.80 * shade) + 0.16 * lampL * lampL * (0.25 + 0.75 * d0);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float3 body = mg_shade(pal, clamp(0.05 + 1.05 * lit, 0.0, 0.90));
    float3 em = mg_shade(pal, 0.80) * (0.50 * pow(clamp(lit, 0.0, 1.0), 2.2)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - 5. Mirage

// MIRAGE. Layered air bending a distant light.
//
// An inferior mirage is one specific piece of optics and it is worth building
// the actual thing rather than a shimmer effect. Air just above hot tarmac is
// less dense than the air above it, so rays that would have passed into the road
// bend back up, and below a certain angle the eye receives a SECOND, INVERTED
// image of whatever is far away. That is why a hot road looks wet: what you are
// seeing is the sky, folded.
//
// So the geometry is a fold, and the fold is the species:
//
//     above the inversion   the distant field is sampled straight
//     below it              it is sampled at -d * m, mirrored and compressed
//
// blended across a narrow band so the map is C1 and no crease is ever an edge.
// Where the two branches meet, the far field is sampled twice at nearly the same
// height and the light there doubles: that bright line along the horizon is the
// mirage's own caustic, and it comes out of the mapping for free rather than
// being drawn.
//
// The shimmer is a vertical DISPLACEMENT of the sampling height, from a field
// whose domain is stretched wide and squeezed tall so it comes out in layers,
// travelling sideways with time. That is what heat does: it stratifies, and the
// strata slide along the road. Both branches take the displacement, but at
// different strengths, so the mirrored image tears differently from the real one
// and the pair never reads as a literal reflection.
//
// The distant subject is a field, not a bar of light: a horizontally stretched
// fBm windowed by a Gaussian in the sampling height, so the far glare has bright
// stretches and dim ones the way a real horizon does.
//
//   c0 bands     how finely the air is stratified.
//   c1 bend      displacement amplitude. Zero is a still hot day, one is the
//                road boiling.
//   c2 distance  how far away the subject is. Far means a thin compressed band
//                and a hard-squashed mirror; near means a tall open one. It is
//                the dial that changes the composition most.
//   c3 haze      the veiling glare that fills the space between the layers.
//                Without some of it the frame reads as two lights in a void.
[[ stitchable ]] half4 mg_mirage(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float bands = clamp(c0, 0.0, 1.0);
    float bend = clamp(c1, 0.0, 1.0);
    float dist = clamp(c2, 0.0, 1.0);
    float haze = clamp(c3, 0.0, 1.0);

    // The horizon sits a little above centre so the road has room. It is fixed
    // in the circle; only the field's scale answers to formScale.
    const float hor = -0.045;
    float x = uv.x / S;
    float d = (uv.y - hor) / S;          // positive below the horizon, on the road

    // THE LAYERS. Domain stretched 4x across and squeezed down, travelling
    // sideways with time. Two octaves rather than three, because a third puts
    // the finest band under three points at 46 pt and horizontal bands at that
    // pitch are the first thing in this pack that would alias.
    float3 bp = float3((x + t * 0.105) * 0.80, d * (2.8 + 5.0 * bands), t * 0.19);
    float band = mg_fbm3(bp, 2, 2.03, 0.5);

    // THE FOLD. m > 1 squashes the mirrored copy, which is what distance does to
    // it. The blend band is narrow enough to read as a seam and wide enough that
    // the slope never breaks.
    float m = 1.15 + 0.90 * dist;
    float fold = smoothstep(-0.035, 0.035, d);
    float yy = mix(d, -d * m, fold);

    // The bending is strongest in the hot layer and dies above the horizon, and
    // the mirrored branch gets more of it because its rays spent longer near the
    // road. That asymmetry is what stops the pair reading as a mirror.
    float grip = smoothstep(-0.070, 0.150, d);
    float ys = yy + band * (0.012 + 0.052 * bend) * grip * (1.0 + 0.55 * fold);

    // THE SUBJECT. Stretched 3x across so it reads as distance rather than as
    // texture, and crawling almost imperceptibly in its third axis so the far
    // light is never a frozen backdrop.
    float3 dp = float3(x * 1.35, ys * (2.2 + 2.6 * dist) + 5.7, t * 0.045);
    float far = 0.5 + 0.5 * mg_fbm3(dp, 3, 2.03, 0.5);

    // The glare's window. Gaussian, so there is no edge on it anywhere.
    float sig = 0.052 + 0.078 * (1.0 - dist);
    float g = ys / sig;
    float win = exp(-g * g);
    float veil = exp(-0.25 * g * g);

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float lit = win * (0.26 + 0.62 * far) + veil * haze * 0.26 * (0.55 + 0.45 * far);
    // The layers of air do not only bend the light, they carry different amounts
    // of it. A light touch: this is the difference between layered air and a
    // striped filter over the frame.
    lit *= 0.80 + 0.20 * (0.5 + 0.5 * band);

    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.90));
    float3 em = mg_shade(pal, 0.80) * (0.40 * pow(clamp(lit, 0.0, 1.0), 2.6)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}

// MARK: - The arc

/// THE APERTURE LAW, written in the shape of the pour's pv_exhale_law: state
/// the motion as a law, take the position as its exact integral, and never let a
/// frame depend on the frame before it. Sample it at any t at all, from a
/// screenshot rig or a scrubbed slider or an app resumed from the background,
/// and it lands exactly where the animation would have been.
///
/// The law is relaxation. What is left to open closes on itself at a rate
/// proportional to how much is left, which is the same differential equation as
/// a breath being let out and the same one every settling thing in this house
/// obeys:
///
///     c'(tau) = -k c(tau),   c(0) = 1     so   c(tau) = e^(-k tau)
///     open(tau) = 1 - c(tau)              the exact integral of k e^(-k tau)
///
/// k is 3 / openTime rather than 1 / openTime so the dial means what it says: at
/// tau = openTime the aperture is within five per cent of open, which is the
/// instant a person would call it arrived. Returns (open, speed, remaining),
/// where `remaining` is the still-opening fraction the way pv_exhale_law's third
/// component is the still-moving one.
///
/// Note what the law does NOT do: it does not keep a floor of motion, the way
/// the exhale's speed does. An aperture that kept opening forever would leave
/// the frame. The whisper of life at rest belongs to the medium instead, which
/// is the honest place for it: the air in the beam and the torn lip of the
/// opening go on drifting after the opening itself has arrived.
static inline float3 mg_open_law(float tau, float openTime) {
    float T = max(openTime, 0.50);
    float k = 3.0 / T;
    float e = exp(-k * max(tau, 0.0));
    return float3(1.0 - e, k * e, e);
}

// MARK: - 6. Oculus

// OCULUS. A soft aperture admitting light, opening as the thought completes.
//
// The arc style of this pack, and the one with the most obvious way to fail: an
// aperture is a round hole, the indicator is a round hole, and a lazy version of
// this is a glowing ball inside a circle, which is the fibonacci dot sphere the
// whole package exists to not be. Four things keep it an opening:
//
//   the edge is TORN. Its radius is a noise field evaluated on the unit circle,
//   which is periodic in the angle by construction and so has no seam at the
//   wrap. About seven bays around the rim at the base octave, wandering. It is
//   never a circle at any instant.
//   the light LEANS. What comes through an oculus comes from a direction, so the
//   interior brightens toward the upper left and falls away opposite. A radially
//   symmetric interior is what makes a hole look like a ball.
//   the interior has STRUCTURE. Two octaves of slow field, so the admitted light
//   is a piece of sky and not a fill.
//   the beam is made of AIR. The glow outside the opening is the interior light
//   carried into the medium and multiplied by a fine drifting field, so its
//   falloff is textured rather than smooth. That texture is `dust`, and it is a
//   density, never motes: the frequency is held low enough that at 46 pt the
//   finest structure is over three points across and reads as air.
//
// THE ARRIVAL. tau is measured from `epoch` and the aperture opens on
// mg_open_law over 2.6 s, which is about the length of a thought that has
// finished. The still-opening fraction does one extra job while it lasts: the
// lip is more agitated during the opening and settles as it arrives, so a
// photograph at half a second and a photograph at eight are visibly different
// pictures rather than the same picture at two offsets.
//
// The open time is deliberately NOT divided by `speed`. Like the pour's
// exhaleTime it is a number of real seconds describing an event, and it has to
// keep meaning that whatever the house tempo dial says. `speed` drives the
// medium, which is the thing that is still moving afterwards.
//
// AND AT REST IT IS STILL ALIVE. The opening arrives, the law goes quiet, and
// three fields keep drifting under it: the lip wanders, the sky inside turns,
// the air in the beam moves through. Nothing pulses. Settled here is a whisper,
// which is what the family asks for and what a frozen frame would not give.
//
//   c0 aperture  the rest radius of the opening.
//   c1 rim       how much light the material's own lip catches, and how defined
//                that lip is. High is stone with an edge; low is an opening in
//                something soft.
//   c2 beam      how far the admitted light carries into the medium outside.
//   c3 dust      how much fine air-structure the light shows. A density, and
//                the frequency is capped so it can never resolve into specks.
[[ stitchable ]] half4 mg_oculus(
    float2 position,
    half4  currentColor,
    float2 size,
    float  time,
    float  pixelScale,
    half4  inkColor,
    half4  toneColor,
    float  hueShift,
    float  formScale,
    float  speed,
    float  depth,
    float  glow,
    float  c0,
    float  c1,
    float  c2,
    float  c3,
    float  epoch
) {
    float2 res = max(size, float2(1.0));
    float2 uv = (position - 0.5 * res) / min(res.x, res.y);

    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);
    float apertureK = clamp(c0, 0.0, 1.0);
    float rimK = clamp(c1, 0.0, 1.0);
    float beamK = clamp(c2, 0.0, 1.0);
    float dustK = clamp(c3, 0.0, 1.0);

    // THE ARC. Real seconds, measured from the epoch the view hands in.
    float tau = max(time - epoch, 0.0);
    float3 law = mg_open_law(tau, 2.6);

    float r = length(uv);
    float ang = atan2(uv.y, uv.x);

    // The rest radius, and the seam it opens from. R0 is not zero: an aperture
    // that starts fully shut starts as a black disc, and a thinking indicator
    // that begins as nothing has a frame where it looks broken.
    float Rrest = (0.100 + 0.150 * apertureK) * S;
    float R = mix(0.022 * S, Rrest, law.x);

    // THE TORN LIP. Sampled on the unit circle, so it is periodic in the angle
    // with no wrap seam anywhere. f = 1.1 puts about seven bays around the rim
    // at the base octave; the second octave doubles that at a quarter of the
    // amplitude, which is a torn edge rather than a scalloped one. The third
    // axis is the wander that keeps this alive after the opening has arrived.
    float2 ring = float2(cos(ang), sin(ang)) * 1.10;
    float tearN = mg_fbm3(float3(ring, t * 0.13), 2, 2.03, 0.5);
    // Agitated while it opens, settled when it has. The 0.30 is the only place
    // the arc touches anything but the radius.
    float Ra = R * (1.0 + (0.16 + 0.30 * law.z) * tearN);

    // THE EDGE. Soft by default; `rim` tightens it toward a defined lip.
    float w = (0.050 + 0.085 * (1.0 - rimK)) * S;
    float pass = 1.0 - smoothstep(Ra - w, Ra + w, r);

    // THE LEAN. Light through an opening comes from somewhere.
    const float2 dir = float2(-0.55, -0.835);
    float lean = 0.58 + 0.42 * smoothstep(-Rrest, Rrest, dot(uv, dir));

    // THE SKY BEYOND. Two octaves at f = 6.5 puts the finest cell at 0.076 uv,
    // three and a half points at 46 pt: structure in the light, not grain.
    float3 ip = float3(uv * (6.5 / S) + float2(0.0, -t * 0.085), t * 0.10);
    float inner = 0.5 + 0.5 * mg_fbm3(ip, 2, 2.03, 0.5);

    // THE AIR. f = 7.0 over two octaves is the finest field in this pack and it
    // sits exactly on the scale rule: 0.070 uv, three points at 46 pt. Anything
    // finer becomes motes, and motes are the one thing this package must never
    // draw.
    float3 ap = float3(uv * (7.0 / S) + float2(t * 0.022, -t * 0.058), t * 0.19);
    float air = 0.5 + 0.5 * mg_fbm3(ap, 2, 2.03, 0.5);
    air = 1.0 - dustK * 0.55 * (1.0 - air);

    // THE BEAM. The admitted light carried outward through the air. Exponential,
    // so it has no end anywhere; textured, so it has no smooth halo either.
    float beam = exp(-max(r - Ra, 0.0) / ((0.045 + 0.115 * beamK) * S)) * air;

    // THE LIP. A band of the material's own edge catching the light, sitting
    // just OUTSIDE the opening and brighter on the lit side. Gaussian, and never
    // a full ring, because a closed bright ring is a drawn shape and this family
    // does not draw shapes.
    float lipW = (0.028 + 0.040 * rimK) * S;
    float lg = (r - Ra * 1.05) / lipW;
    float lip = exp(-lg * lg) * rimK * lean;

    MGPalette pal = mg_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = mg_srgb_to_linear(float3(inkColor.rgb));

    float through = pass * lean * (0.42 + 0.58 * inner);
    float lit = 0.04 + 0.84 * through + 0.30 * beam * (0.35 + 0.65 * pass * 0.0 + 0.65 * lean)
              + 0.34 * lip;
    float3 body = mg_shade(pal, clamp(lit, 0.0, 0.92));
    float3 em = mg_shade(pal, 0.80) * (0.55 * pow(clamp(through, 0.0, 1.0), 2.0)) * max(glow, 0.0);

    float3 rgb = mix(inkLin, body + em, mg_hold(uv, 0.60));
    rgb = float3(mg_knee(rgb.r, 0.88), mg_knee(rgb.g, 0.88), mg_knee(rgb.b, 0.88));
    return mg_out(rgb, position * pixelScale);
}
