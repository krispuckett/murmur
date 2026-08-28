// The Liquid pack. Eight thinking indicators made of molten weight: the pour's
// blood, none of the pour's form.
//
//   ml_eddy        thought circling a centre. A vortex's differential rotation,
//                  applied to the coordinate the material is read against, so
//                  the inner turn outruns the outer one and the mass winds into
//                  arms it did not have a moment ago.
//   ml_well        a sink. A radial remap of the plane, scrolled, carries the
//                  material inward and stretches it into wisps on the way; the
//                  throat stays dark, because a well that fills is a puddle.
//   ml_tide        a body of liquid sloshing in a bowl. The speed is a sine, the
//                  position is its exact integral, and the surface leans with
//                  the mass rather than against it.
//   ml_undertow    two sheets sliding opposite ways past each other. What is
//                  drawn is neither sheet: it is the seam where they read the
//                  same value, which belongs to both and travels with neither.
//   ml_meander     one broad channel on a single slow arc through dark ground,
//                  its banks soft dark shoulders, the light inside it
//                  travelling downstream while the arc itself re-cuts.
//   ml_confluence  two flows finding each other and joining, on their own
//                  diagonal. An arc: the approach is a law, the distance
//                  travelled is that law's exact integral, and joined is the
//                  rest state, still moving, still turning over at the meeting.
//   ml_melt        a heavy lump of iron softening under its own heat. An
//                  implicit surface, so its drips stretch necks and are taken
//                  back rather than falling; the body rings when one lands.
//   ml_glaze       a thin film sliding over a dark form, pooling in its
//                  hollows, brightest at its own edge, with the light inside
//                  running faster than the film that carries it.
//
// WHAT THE FAMILY SHARES, AND WHY THAT IS NOT A LIMIT. These eight are one
// ecosystem, not one animal. The shared blood is the material and the light:
// warm liquid light computed per pixel out of gradient noise, walked through the
// house OKLAB rail so a single hue family holds, kneed where it runs hot, and
// written once through the triangular dither. Everything ABOVE that is species:
// each one has its own body and its own physics, and no two are the same field
// with a different frequency. The pour pack's record is the reason for the rule.
// Two waves of shaders built from a DESCRIPTION of a loved material were
// rejected; the wave that started from the material's own code was not. So the
// kit here is copied, and the forms above are invented from a physics rather
// than tuned from a rule list.
//
// AND WHAT IT IS NOT. Not the pour. The pour is a wall of falling streams read
// through a window, and its whole grammar is vertical. Nothing here falls. These
// turn, sink, wash, shear, wander and join, which are six things liquid does
// that are not pouring. The one place a stream appears (meander, confluence) it
// runs ACROSS the frame, because a bright line running down a small circle is
// the pour wearing a disguise.
//
// THESE ARE INDICATORS, WHICH CHANGES THE BUDGET AND THE BAR.
//
//   the frame     every function centres with uv = (position - 0.5 size) /
//                 min(size), so the field is size-independent and correct in a
//                 non-square view. The VIEW clips to a circle at length(uv) =
//                 0.5. A clip that cuts a form is a form with a hard edge, and
//                 organic forms do not have those, so ml_bowl brings every last
//                 photon down to pure ink by length(uv) = 0.45 and the clip
//                 never has anything left to cut.
//   the ceiling   calm is the bar, and calm is mostly a ceiling. The rail runs
//                 ink -> warm shadow -> tone -> pale specular; these fields live
//                 between about 0.05 and 0.80 on it, so the brightest thing on
//                 screen is the tone with a little light behind it and the pale
//                 stop is somewhere they can reach, not somewhere they sit.
//   the tempo     ATTENTION, NOT ATMOSPHERE. The first tune of this pack was
//                 built to the ambient bar the pour is held to, and on device it
//                 read as one notch too still: a thinking indicator is a
//                 statement that work is happening, and an ambient card is not.
//                 Every internal rate was lifted 1.5x to 1.9x, carriers further
//                 than details so the set reads faster without reading busier.
//                 The fastest thing in the pack now crosses the disc in about
//                 ten seconds and the slowest in twenty. Nothing here pulses:
//                 the family verbs are FLOW and SETTLE, and a brightness that
//                 breathes is neither.
//   the cost      fixed-count loops, fBm at three octaves, nine field taps a
//                 pixel at the worst (confluence) and three at the best (well).
//                 An indicator at 46 pt has to be free, and a 300 pt one has to
//                 hold up in a full-screen studio at the same time.
//   the light     glow drives EMISSION only, never the base. Scaling the shaded
//                 colour would darken the ink itself and put a ring around a
//                 field that is supposed to dissolve into its pill.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal VERBATIM under an ml_ prefix, the way the pour
// pack did it, with the comments carried along because the reasoning is the part
// worth carrying. Copied, unchanged except for the name:
//
//   ml_hash, ml_grad3, ml_noise3, ML_ROT, ml_fbm3, ml_hash1, ml_vnoise1,
//   ml_fbm1, ml_srgb_to_linear, ml_linear_to_srgb, ml_linear_to_oklab,
//   ml_oklab_to_linear, ml_lch, MLPalette, ml_palette, ml_shade, ml_out,
//   ml_knee (the last from FieldPackPour.metal, which is where the pack rail
//   and the knee were last carried together).
//
// Not copied: fl_noised3 and fl_fbmd3, because nothing here lights a surface off
// its own slope; fl_edge, because a rectangular vignette is the wrong shape for
// a circle and ml_bowl is its radial equivalent; the whole wave-two kit, because
// this pack has no journey, no streak and no perspective camera. Copying kit a
// pack never calls only leaves dead code behind a prefix.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's (and, for the knee,
// FieldPackPour.metal's), verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint ml_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 ml_grad3(int3 c) {
    uint h = ml_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float ml_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(ml_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(ml_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(ml_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(ml_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(ml_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(ml_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(ml_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(ml_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse, which
/// is exactly what the chain rule below needs. Without it every octave stacks on
/// the same lattice axes and the field grows a visible plaid.
constant float3x3 ML_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

static float ml_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * ml_noise3(q);
        amp *= gain;
        q = lacunarity * (ML_ROT * q);
    }
    return value;
}

// MARK: 1D value noise
//
// The 3D gradient field above is the right tool when a surface has to be lit,
// and the wrong one when all that is wanted is a wandering scalar along a line:
// it costs thirty two hashes an evaluation. This costs two. The meander's
// centreline takes three of these a pixel and the confluence's two arms take
// two more, and neither would fit in a frame at the other price.

static inline float ml_hash1(float cell, float lane) {
    return float(ml_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float ml_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(ml_hash1(i, lane), ml_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float ml_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * ml_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

// MARK: OKLAB and the family

static inline float3 ml_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 ml_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 ml_linear_to_oklab(float3 c) {
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

static inline float3 ml_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 ml_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the day tone the ribbon wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MLPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MLPalette ml_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = ml_linear_to_oklab(ml_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = ml_linear_to_oklab(ml_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MLPalette p;
    p.s0 = ink;
    p.s1 = ml_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = ml_lch(L, C, h);
    p.s3 = ml_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; ml_out does the encoding.
static float3 ml_shade(MLPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return ml_oklab_to_linear(lab);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float ml_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 ml_out(float3 linearRGB, float2 pixel) {
    float3 c = ml_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

// MARK: - The pack's own frame
//
// Three small things every species in this file shares. They are NOT copied kit;
// they are what makes six generative fields into six indicators.

/// THE BOWL. fl_edge's job, in the shape this pack actually lives in.
///
/// The lab's fields fade toward a rectangle because a rectangle is what they
/// fill. An indicator is a circle, and the circle is enforced by a clip in the
/// view, which is a hard edge by definition. So the light has to be gone before
/// the clip arrives: r is measured so that 1.0 is exactly the clip, the fade
/// begins at 0.54 of it and is complete at 0.90, which leaves a tenth of the
/// radius of pure ink under the rim. That last tenth is the whole point. It is
/// also why these read as a body of material floating in a pill rather than as a
/// texture stamped into a hole.
static inline float ml_bowl(float2 uv) {
    float r = length(uv) * 2.0;                  // 1.0 at the view's own circle
    return 1.0 - smoothstep(0.54, 0.90, r);
}

/// THE WRITE. Every species ends here, and the order is the argument.
///
/// `t` walks the rail and nothing else does: accent comes from moving along the
/// family, never from a second hue. `hot` is the fraction of the material that
/// is bright enough to have light of its own, and it is the ONLY thing `glow`
/// touches. That split is deliberate: the base colour at t = 0 is the ink
/// exactly, so a field with nothing in it is the pill's own ground to the bit,
/// and scaling that by a presence dial would draw a dark ring around a shape
/// that is supposed to have no shape at all.
///
/// The emission is a tonal lift, not a spatial blur. The pour needs eleven taps
/// of real Gaussian because its material is sixty sharp columns under a
/// magnification; these fields are three octaves of gradient noise and are
/// already broad, so a blur would cost eleven times the frame to soften
/// something that has no hard structure to soften. Where a species genuinely
/// wants light spilling into the air around a form (the two channel species) it
/// gets a real, wider second Gaussian in closed form, which is free.
///
/// `emRail` IS WHERE THE EMITTED LIGHT SITS ON THE RAIL, and it is a per-species
/// number because the pour pack's pv_tint comment is right and this pack proved
/// it again. Past about 0.86 the rail is walking into the pale specular, whose
/// chroma is roughly half the tone's; adding that to a field that is already at
/// the tone does not make hot amber, it makes a desaturated grey-white that
/// reads out of the family next to its neighbours. A species whose material
/// spends most of its time near the tone (undertow) has to emit BELOW that, at
/// 0.80, where the added light is still saturated. A species that is mostly dark
/// with small hot cores can safely emit at 0.88, because the pale light lands on
/// ink and not on more tone.
///
/// Then the knee at 0.90, then the dither. A hot tone with the glow up used to
/// clip and turn the crest into flat paper with banded arcs at its edge; below
/// the knee nothing changes and above it the tail compresses into light instead.
static inline half4 ml_write(MLPalette pal, float3 inkLin, float t, float hot,
                             float emRail, float glow, float contain, float2 pixel) {
    float3 lit = ml_shade(pal, t);
    float3 em = ml_shade(pal, emRail) * (0.42 * clamp(hot, 0.0, 1.5) * max(glow, 0.0));
    float3 rgb = mix(inkLin, lit + em, contain);
    rgb = float3(ml_knee(rgb.r, 0.90), ml_knee(rgb.g, 0.90), ml_knee(rgb.b, 0.90));
    return ml_out(rgb, pixel);
}

/// The centred, aspect-preserved frame every function opens with. length(uv) is
/// 0.5 at the view's circle whichever way the view is stretched.
static inline float2 ml_uv(float2 position, float2 size) {
    return (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
}

// MARK: - The states
//
// Two of the five states are expressed in the shader; the other three are
// carried entirely by the per-state parameter sets the Swift layer interpolates.
// Both of the two are one mechanism shared by all eight species, for the same
// reason the tic is: eight hand-rolled arrivals would be eight characters.

struct MLState {
    float surge;   // the success flash's strength, exactly 0 when not arriving
    float front;   // where its wave has reached, in the species' own 0..1
    float lift;    // the settled brightness the flash leaves behind
    float drive;   // responding: directional urgency, 0..1, held
    float push;    // the DISTANCE that urgency has carried, in closed form
};

/// SUCCESS is a wave, not a flash. A flash is a brightness multiplier applied to
/// the whole disc at once, which this family is not allowed to do and which
/// would read as a white overlay whatever colour it was. A wave has somewhere to
/// be: it enters the material at one end of the species' own structure, travels
/// through it, and leaves at the other, and every pixel it passes is the
/// material's OWN light turned up while the crest is on it. Around the eddy's
/// turn, out of the well's mouth, across the tide's wash, down the meander's
/// channel. The front starts at -0.30 and ends at 1.30 so it is already moving
/// when it arrives and still moving when it goes.
///
/// RESPONDING is a rate, and rates are the dangerous kind of state. Scaling an
/// advection that reads `rate * T` makes the material JUMP the instant the rate
/// changes, because T is large and the whole accumulated distance rescales with
/// it. The eddy's winding taught this pack that lesson once already. So the
/// drive is published as a DISTANCE as well as a strength: `push` is the exact
/// integral of the drive ramp, so a style adds `driveRate * push` to its
/// advection and gets urgency that starts from where the material already was.
///
///   drive(tau) = smoothstep(0, 0.45, tau)
///   push(tau)  = 0.45 (k^3 - k^4/2), k = tau/0.45,  for tau <= 0.45
///              = tau - 0.225                        after
static inline MLState ml_state(float stateIndex, float stateTau) {
    MLState s;
    s.surge = 0.0; s.front = 0.0; s.lift = 0.0; s.drive = 0.0; s.push = 0.0;
    float tau = max(stateTau, 0.0);

    if (abs(stateIndex - 3.0) < 0.5) {
        const float D = 1.20;                 // the arrival's whole window
        float x = min(tau / D, 1.0);
        s.front = mix(-0.30, 1.30, x);
        s.surge = smoothstep(0.0, 0.13, x) * (1.0 - smoothstep(0.70, 1.0, x));
        // What it leaves behind: the material settles a little brighter than it
        // was and lets that go over a couple of seconds, handing off to the
        // success state's own parameter set rather than ending on a step.
        s.lift = smoothstep(0.45, 1.0, x) * exp(-max(tau - D, 0.0) / 2.4);
    } else if (abs(stateIndex - 2.0) < 0.5) {
        float k = min(tau / 0.45, 1.0);
        s.drive = k * k * (3.0 - 2.0 * k);
        s.push = (tau <= 0.45) ? 0.45 * (k * k * k - 0.5 * k * k * k * k)
                               : tau - 0.225;
    }
    return s;
}

/// The crest, at one point of a species' own structure. `s01` is that point's
/// progress through the material along whatever axis the species actually flows
/// down: an angle for the eddy, a radius for the well, the channel for the
/// meander. Gaussian, so the wave has no edge anywhere in it.
static inline float ml_crest(float s01, MLState st, float width) {
    float d = (s01 - st.front) / max(width, 1e-3);
    return st.surge * exp(-d * d);
}

/// The same crest on a coordinate that WRAPS, an angle, where the shortest way
/// round is the honest distance and the wave therefore has no seam to cross.
static inline float ml_crest_wrap(float s01, MLState st, float width) {
    float d = s01 - st.front;
    d -= floor(d + 0.5);
    return st.surge * exp(-(d * d) / max(width * width, 1e-6));
}

/// THE TIC. Every species here has one, and it is the same clock in all eight.
///
/// A personality tic is not a behaviour, it is a flourish: something the
/// material does now and then and then lets go of. Three properties make the
/// difference between that and a mechanism, and all three are in this function
/// rather than in the eight places that call it, because eight hand-rolled
/// timers would drift into eight different characters.
///
/// IT IS NOT A METRONOME. Time is cut into 6.5 second slots and each slot's
/// gesture starts at its own hashed offset within +/- 1.25 seconds of the slot
/// line. Consecutive starts are therefore 6.5 + (j2 - j1) apart, which lands
/// everywhere in 4 to 9 seconds and never twice the same. The hash is the kit's
/// own, so this is a pure function of t: scrub, screenshot or resume and the
/// gesture is exactly where it would have been.
///
/// IT NEVER SNAPS. The envelope rises over the first third and releases over the
/// remaining two, both on smoothsteps, so it leaves and enters zero with zero
/// slope. Quick in and slow out, because that is the shape of a thing being
/// done deliberately and then relaxed, where the mirror image is the shape of a
/// thing recoiling.
///
/// IT IS EXACTLY ZERO BETWEEN GESTURES. Not small: zero, on the nose. Every
/// caller adds its gesture as a term scaled by this envelope, so between tics
/// the arithmetic is the approved material to the bit. Nothing here is allowed
/// to leave a residue.
///
/// Callers pass their own `lane` AND their own phase offset in `t`. Same slot
/// length everywhere would otherwise have all eight styles flourishing inside
/// the same two and a half second window, which in a gallery is a stadium wave.
///
/// Returns (envelope, pick), where pick is a stable hash of whichever gesture is
/// running, for the species that need to choose something to do it to.
static inline float2 ml_tic(float t, float lane, float dur) {
    const float L = 6.5;      // the slot
    const float J = 1.25;     // half the jitter, so starts fall 4 to 9 apart
    float e = 0.0, pick = 0.0, best = 0.0;
    float k0 = floor(t / L);
    for (int i = -1; i <= 1; i++) {
        float k = k0 + float(i);
        float s = k * L + (ml_hash1(k, lane) * 2.0 - 1.0) * J;
        float x = (t - s) / max(dur, 0.05);
        float b = (x > 0.0 && x < 1.0)
                ? smoothstep(0.0, 0.35, x) * (1.0 - smoothstep(0.35, 1.0, x))
                : 0.0;
        e += b;
        if (b > best) { best = b; pick = ml_hash1(k + 811.0, lane); }
    }
    // The duration is always under the shortest possible gap, so two gestures
    // can never overlap; the clamp is belt and braces for an odd `dur`.
    return float2(min(e, 1.0), pick);
}

// MARK: - 1. Eddy

// EDDY. Thought circling a centre.
//
// THE PHYSICS. A vortex is not a spinning picture; it is a field whose angular
// speed depends on how far out you are. Rotate the coordinate the material is
// READ against by an angle that falls off with radius, and a blob that was round
// a moment ago is drawn out into an arm, because its inside has gone further
// round than its outside. Nothing is painted as a spiral. The spiral is what
// differential rotation does to whatever happens to be there, which is what it
// does in water.
//
//   omega(r) = W * ((R0 + RC) / (r + RC))^fall
//
// RC = 0.17 is the core's softening radius and it is doing real work: without it
// omega goes to infinity at the centre and the middle pixel winds up a hundred
// turns while its neighbour winds up two, which aliases into a hard dot. R0 =
// 0.25 is a reference ring at about half the disc, and dividing by it is what
// lets `shear` change the SHAPE of the falloff without changing the speed of the
// picture: at any shear setting the material at mid-radius turns at W, and only
// the difference between inside and outside moves. That separation is the
// difference between a knob that tightens the spiral and a knob that also speeds
// the whole thing up, and the second one is unusable.
//
// WHY IT NEVER WINDS ITSELF SHUT. Differential rotation applied forever makes
// infinitely tight spirals. Real eddies do not, because the water in them is
// continuously replaced. So is this: the noise drifts along its third axis, and
// old structure decorrelates in ten to fifteen seconds, which at these rates is
// under half a turn of winding. The field can never get tighter than that no
// matter how long the view is left running.
//
// THE CENTRE IS DIMMED, slightly and on purpose. A vortex core is a low pressure
// void: there is less material there, not more. It is also where omega is
// highest, so it is where a bright pixel would alias first. The 0.52 floor
// darkens it enough to be honest and not enough to punch a hole, which would be
// the well's job and not this one's.
//
//   c0 swirl   how fast the turn goes at mid-radius
//   c1 drift   how far the core wanders across the disc, and how fast old
//              structure is replaced (one dial, because they are one idea: a
//              turn that stays put and never renews is a wallpaper)
//   c2 grain   a fine tap over the three broad octaves, for the 300 pt view
//   c3 shear   how steeply omega falls with radius: 0 is nearly rigid, 1 is a
//              tight core dragging a slow rim
[[ stitchable ]] half4 ml_eddy(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float swirl = clamp(c0, 0.0, 1.0);
    float drift = clamp(c1, 0.0, 1.0);
    float grain = clamp(c2, 0.0, 1.0);
    float shear = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    // The core wanders. Two incommensurate rates, so it traces a slow open curve
    // that never repeats inside a session and never looks like an orbit.
    float2 core = (0.028 + 0.070 * drift) * float2(sin(T * 0.199), cos(T * 0.155 + 1.7));
    float2 p = uv - core;
    float r = length(p);

    const float RC = 0.17;   // core softening: keeps omega finite at the middle
    const float R0 = 0.25;   // the reference ring the speed is pinned to
    float fall = mix(0.55, 1.45, shear);
    float prof = pow((R0 + RC) / (r + RC), fall);

    // THE TWIST IS SPLIT, AND THE DIFFERENTIAL HALF IS BOUNDED. This is the
    // correction to a claim made in an earlier comment here, which said the
    // noise's own renewal stopped the coil winding shut. It does not, and the
    // reasoning was wrong in an instructive way: renewal changes WHICH material
    // is being sampled, but the winding lives in the MAP from screen to domain,
    // and that map keeps accumulating omega(r) * t whatever the material does.
    // Rendered at two minutes the flagship style was a bullseye of concentric
    // rings, and at five it was aliasing into moire. The first sheets only ran
    // to thirteen seconds, which is how it survived three waves of review.
    //
    // A rigid rotation is harmless: it turns the picture and never tightens it.
    // Only the DIFFERENCE between one radius and another winds anything up. So
    // the rim's own rate is separated out and allowed to run forever, and the
    // excess above it accumulates through a knee instead of a straight line:
    // linear for the first ten seconds, so every approved frame is untouched,
    // then asymptotic to a twist worth about seventeen seconds. The coil tightens
    // to the shape it was approved at and then stays there, still turning.
    const float PR_R = 0.677;             // (R0 + RC) / (0.45 + RC), the bowl's rim
    const float KMAX = 24.0;
    float PR = pow(PR_R, fall);
    float amp = 0.110 + 0.300 * swirl;
    // THE RIGID RATE IS LIFTED OFF THE RIM'S OWN VALUE, and that is the motion
    // fix. Once the differential twist was bounded, the only thing left running
    // forever was the rim's rotation, and at a turn every thirty six seconds the
    // honest description of this style became "it kind of shifts around". A
    // vortex's verb is CIRCLES. Adding 0.52 to the profile takes the whole
    // picture round in about twenty seconds, which the eye reads as turning
    // without ever reading as a spinner, and it costs nothing in shape: a rigid
    // rotation moves the orientation and cannot tighten or loosen a coil.
    float rigid = amp * (PR + 0.52);               // may run forever
    float diff = amp * max(prof - PR, 0.0);        // must not
    float TW = KMAX * ml_knee((T + 7.0) / KMAX, 0.70);

    // THE TIC: THE COIL TIGHTENS. An extra twist winds on and unwinds, and it
    // rides the SAME radial profile the rotation does, so the core takes about a
    // third of a turn more than the rim and the arms draw in on themselves
    // before letting go. It is an angular OFFSET and not a rate, which is the
    // whole trick: a rate boost would leave the field permanently further round
    // than it should be, since the twist is measured against accumulated time.
    // An offset returns the material to exactly where the clock says it belongs.
    float2 tic = ml_tic(T + 0.0, 3.0, 2.3);

    // Time enters HERE, in the coordinate, and only here.
    //
    // The field is not born unwound. Rendered from a standing start it is a
    // scatter of round blobs for its first several seconds and only becomes an
    // eddy once the differential rotation has had time to draw them out, and a
    // thinking indicator does not get several seconds to become itself. So the
    // twist is measured from seven seconds before the view appeared. That is not a
    // cheat: seven seconds is where winding and renewal balance, so it is the
    // state the field settles into and stays in. Starting there means the first
    // frame is the steady state and every frame after it is too.
    // Responding leans on the turn, as a distance rather than a rate.
    float th = rigid * (T + 7.0) + amp * 0.95 * st.push
             + diff * TW + tic.x * 0.50 * prof;
    float cs = cos(th), sn = sin(th);
    float2 q = float2(cs * p.x - sn * p.y, sn * p.x + cs * p.y);

    float f = 3.8 / S;     // about three broad forms across the disc
    float3 dom = float3(q * f, (0.085 + 0.110 * drift) * T);
    float n = ml_fbm3(dom, 3, 2.03, 0.5);
    float g = ml_noise3(dom * 2.85 + float3(11.3, 5.1, 0.0));

    float mass = 0.5 + 1.00 * n + 0.17 * grain * g;
    // A wide, soft threshold. Narrower and the arms grow edges; wider and the
    // whole disc is one grey wash with a turn somewhere inside it.
    // Responding tightens the arms: the same field cut harder, so the material
    // gathers into fewer, more definite streams instead of a broad wash.
    // Narrowing the transition from BOTH ends is what "tighter" means. Sliding
    // it down instead just admits more material, which is a brightness change
    // wearing a form change's name, and responding is not a lamp.
    float dens = smoothstep(0.36 + 0.06 * st.drive, 0.88 - 0.10 * st.drive, mass);
    dens *= 0.52 + 0.48 * smoothstep(0.02, 0.19, r);   // the core's void

    // SUCCESS: the surge chases around the turn, twice, riding the ROTATED angle
    // so it follows the arms rather than sweeping the screen. Wrapped, because
    // an angle has no end, and a seam in an arrival would be the one frame
    // everybody notices.
    float ang01 = atan2(q.y, q.x) * (1.0 / 6.2831853) + 0.5;
    dens *= 1.0 + 1.00 * ml_crest_wrap(ang01, st, 0.26) + 0.16 * st.lift;

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.60 * dens;
    float hot = smoothstep(0.58, 1.00, dens);
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 2. Well

// WELL. Pulling inward, toward a deep centre that never fills.
//
// WHY THE POLAR VERSION WAS THROWN AWAY. The first body sampled the noise on a
// cylinder: (cos a, sin a) * ringR for two axes and depth for the third. It is
// seamless, it is cheap, and it is a flower. Sampling a CIRCLE in a noise domain
// gives a function that is periodic in the angle with roughly 2 pi ringR lobes,
// and at any ring count the eye can hold in one glance, six or ten, that is a
// marigold with a black middle. Widening the ring only trades a marigold for a
// pinwheel. The species is not "radiating"; it is PULLING INWARD, and the
// parametrization has to be one where the angle is not a coordinate at all.
//
// SO THE MATERIAL IS SAMPLED IN THE PLANE, at dir * (g(r) + scroll). This is a
// pure radial remap of the pixel's own position: no angle appears anywhere, so
// there is no period to find, and the structure is whatever the noise happens to
// be, drawn out into wisps.
//
//   g(r) = (r + 0.14)^0.60 * F     the remap
//
// The exponent is the whole trick. Because g rises more slowly than r, moving
// one noise cell along a RADIUS takes about five times further on screen than
// moving one cell around the circle does, so every form comes out five times
// longer than it is wide, pointing at the middle. That is the radial draw, and
// it costs one pow. And because g still rises, the circle the sample traces is
// bigger at the rim than at the throat, so there are about fourteen forms around
// the outside and nine at the mouth: streams crowd and merge on the way in,
// which is what falling material does and what stops the count from ever being
// a number the eye can name.
//
// THE SCROLL, AND WHY IT IS CYCLED. Adding a distance to the ring radius walks
// every form inward, and it accelerates because the remap compresses. But that
// distance cannot grow forever: after a minute the forms would be finer than a
// pixel. So it runs on a bounded cycle with TWO layers half a cycle apart,
// cross-faded. Layer j sits at offset (f + j) * CYC with its own slice of the
// noise; at the end of a cycle layer 0 has become exactly what layer 1 was, so
// the recycle happens at the instant the retiring layer's weight is zero and
// nothing on screen jumps. Material arrives at the rim, falls, is consumed, and
// the disc can run all afternoon.
//
// A PRESENCE FLOOR, which the gallery forced. Cut purely on the field, this was
// the dimmest cell in the set and nearly vanished at 76 pt. A well is not a
// place where there is no material; it is a place where material is being taken
// somewhere. So a floor of light rides the convergence and is under the streams
// rather than instead of them: the disc always glows, and the streams are the
// structure inside the glow.
//
// THE THROAT NEVER FILLS. Everything inside r = 0.035 is extinguished, fading in
// over the next eighth of the radius, so the middle is a dark mouth ringed with
// the hottest material in the pack. A well that filled would be a puddle: the
// light has to be spent on the way in rather than arriving.
//
// BARELY SPIRALED. There is a curl, because falling material with any rotation
// at all conserves it, but it is a quarter of what it was: about three quarters
// of a radian of differential twist over a form's whole transit. Enough that the
// wisps lean into the mouth, not enough to be a pinwheel.
//
//   c0 pull        how fast the material falls in
//   c1 depthGlow   how much brighter the material gets as it converges
//   c2 churn       the drain's curl
//   c3 offset      the throat's ECCENTRICITY, not a signed position: 0 is dead
//                  centre, 1 is a third of the radius out, and the direction
//                  turns on its own at a fortieth of a radian a second so no
//                  configuration is ever stuck with a lopsided still frame
[[ stitchable ]] half4 ml_well(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float pull = clamp(c0, 0.0, 1.0);
    float dglow = clamp(c1, 0.0, 1.0);
    float churn = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // Pushed further off centre than it was. A dark round hole in the exact
    // middle of a warm ring is an iris, and an indicator that reads as an eye is
    // reading as something. Off centre it reads as a place the material is
    // going, which is what it is.
    MLState st = ml_state(stateIndex, stateTau);

    float ecc = 0.20 * offset;
    float ea = 0.065 * T + 0.9;
    float2 core = ecc * float2(cos(ea), sin(ea));
    float2 p = uv - core;
    float r = length(p);
    float2 dir = p / max(r, 1e-5);

    // The curl. Differential, so the mouth turns faster than the rim: enough that
    // the wisps lean into the mouth instead of pointing at it, which is most of
    // what stops a radial draw reading as a starburst.
    //
    // Split and bounded for the eddy's reason, and it had the same defect from
    // the same cause: differential rotation applied to a sampling coordinate
    // accumulates in the MAP, so at a few minutes this was a set of concentric
    // rings too, just arriving more slowly. The rim's rate runs forever, the
    // excess above it goes through a knee and settles at a fixed lean.
    const float SC = 0.26, KW = 20.0;
    float spinA = 0.026 + 0.096 * churn;
    float rigidS = spinA / (0.45 + SC);
    float diffS = max(spinA / (r + SC) - rigidS, 0.0);
    float th = rigidS * T + diffS * (KW * ml_knee(T / KW, 0.70));
    float cs = cos(th), sn = sin(th);
    float2 d2 = float2(cs * dir.x - sn * dir.y, sn * dir.x + cs * dir.y);

    // THE WARP, AND WHY THE FIRST RADIAL REMAP WAS STILL A FLOWER. Any map of
    // the form dir * h(r) is rotationally equivariant, so a circle on screen is
    // still a CIRCLE in the noise domain and still carries a whole number of
    // lobes around it. Swapping the cylinder for a radial remap changed the
    // radius profile and nothing else; the marigold came straight back, brighter.
    //
    // What breaks it has to be non-equivariant, and one tap of plain Cartesian
    // noise is. Added to the radius, it makes the sampled curve a wobbly circle
    // rather than a circle: forms are encountered at irregular intervals around
    // it, and because the wobble also varies ALONG the radius, no two streams
    // start or end at the same place. Same spacing, same length and same phase
    // are the three things that were making the eye call it a mechanism, and
    // this removes all three for one noise evaluation.
    float warp = ml_noise3(float3(p * (2.2 / S), 51.0 + 0.045 * T));

    // THE CYLINDER IS BACK, AND THE CROSSFADE IS GONE. This species has now been
    // built three ways and the third one is right for a reason worth writing
    // down: the radial remap could not make the pull LEGIBLE.
    //
    // Sampling at dir * (g(r) + scroll) puts the tangential and radial scales on
    // one number, so asking for longer streaks and asking for more of them fight
    // each other, and the inward motion has to come from growing the ring
    // radius, which grows the feature count without bound and therefore needs a
    // two-layer crossfade to stay finite. That crossfade was the problem. Every
    // few seconds the picture dissolved into a different one, so what the eye
    // read was churn, not fall. Motion you cannot follow is not motion.
    //
    // On a cylinder the two are INDEPENDENT: the ring radius alone sets how many
    // streams go round, the third axis alone is the radius, and the inward pull
    // is a plain translation along that axis. A translation never changes scale,
    // so it can run forever with no recycling and nothing to dissolve. Sixteen
    // streams around at a radius of 2.55, each about two and a half times longer
    // than it is wide, all sliding steadily toward the mouth. The flower that
    // sank the FIRST cylinder came from six lobes and no warp; the warp below
    // and the count above are what make the same construction work now.
    const float RC = 0.14;
    // THE TIC: THE GULP. The mouth opens a little wider and everything falling
    // toward it leans in, then it closes and the fall settles back. Both halves
    // are coordinates: a shove along the radial axis, and a wider extinction
    // radius at the throat. A drain does this when something lets go upstream.
    float2 tic = ml_tic(T + 1.7, 11.0, 2.6);

    // The warp, and it is doing the same job it did in the remap version: any
    // map built on a bare angle is periodic in that angle and reads as a
    // marigold. One tap of plain Cartesian noise added to the angle makes the
    // spacing irregular, and because it varies along the radius too, no two
    // streams start or end together.
    float aa = atan2(d2.y, d2.x) + 0.55 * warp;

    // Inward, at a steady 0.42 of a form-length a second, plus the responding
    // drive as a DISTANCE so urgency never makes the fall jump.
    float travel = 0.42 * (0.55 + 0.90 * pull) * T
                 + 0.60 * (0.55 + 0.90 * pull) * st.push
                 + tic.x * 0.30;
    float Rc = 2.55 / S;                       // sixteen streams around
    float radial = (r + RC) * (4.1 / S);       // about two and a half to one
    float3 dom = float3(cos(aa) * Rc, sin(aa) * Rc, radial - travel);
    float n = ml_fbm3(dom, 3, 2.03, 0.5);

    // A broad envelope, one tap, turning slowly, and it is DOMINANT rather than
    // a modulation. Two things need it. At 76 pt the individual wisps are two
    // points wide and the eye can only read the large light and dark, so without
    // a big shape there is nothing at cell size. And a well fed evenly from
    // every direction is a diagram: real infall arrives from somewhere, so whole
    // sectors of this one go nearly dark and others carry most of the material.
    float env = 0.5 + 0.5 * ml_noise3(float3(p * (1.3 / S), 31.0 + 0.068 * T));

    // Responding tightens the streams: the same field, cut higher, so the wash
    // between them falls away and what is left is the fall itself.
    float streams = smoothstep(0.30 + 0.08 * st.drive, 0.92 - 0.09 * st.drive, 0.5 + 1.05 * n);
    float conv = smoothstep(0.48, 0.10, r);          // 0 at the rim, 1 at the mouth
    // The mouth's edge is RAGGED, on the same warp that irregularises the
    // streams. A clean circle of extinction is a punched hole, and every form
    // terminating on it at once is what made the last cut a sunburst.
    float throat = smoothstep(0.025, 0.165 + 0.075 * warp + 0.100 * tic.x, r);

    float floorLight = 0.20 + 0.22 * conv;           // the presence floor
    float dens = (floorLight + (0.50 + 0.40 * conv) * streams)
               * throat * (0.25 + 1.05 * env);
    // The convergence multiplier is a third of what it first was. Stacked on top
    // of the presence floor it was driving the collar to 0.99 on the rail, and a
    // well whose mouth is white paper is lit from inside, which is the opposite
    // of a well. The floor buys the legibility now; the squeeze only leans on it.
    float lum = 1.0 + (0.30 + 0.60 * dglow) * conv * throat;
    // Kneed at 0.58 rather than clamped: the collar is where this field runs hot
    // and a clamp there draws a hard contour around the mouth.
    // SUCCESS: the surge comes UP the well and out of its mouth, which is the
    // one direction this material never otherwise goes. s01 runs 0 at the throat
    // to 1 at the rim, so the light blooms outward through the streams it
    // arrived down. It multiplies what is there: the dark stays dark.
    float crest = ml_crest(clamp(r / 0.45, 0.0, 1.0), st, 0.30);
    dens *= 1.0 + 0.85 * crest + 0.14 * st.lift;

    float bright = ml_knee(dens * lum * 0.62, 0.58);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.050 + 0.72 * bright;
    float hot = smoothstep(0.66, 1.00, bright) * 0.70;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 3. Tide

// TIDE. A slow wash crossing and returning, with the weight leaning into it.
//
// THE LAW, AND ITS INTEGRAL. The body's speed is a sine and its position is that
// sine's exact integral, which is a cosine, so this field has the same property
// the arc styles have without needing an epoch: sample it at any time at all and
// the water is where the water would be. Nothing accumulates, nothing drifts out
// of phase after ten minutes on screen.
//
//   v(t) = A w sin(w t)      the wash
//   x(t) = -A cos(w t)       where the body is: the integral, exactly
//
// THE SURFACE LEANS WITH THE MASS, not against it. The tilt is proportional to
// x, so it is steepest at the two turns, where the water has finished piling up
// against one side, and flat as the body crosses the middle at full speed. Water
// in a bowl does that. A surface that leaned with the VELOCITY would be steepest
// in the middle of the crossing, which looks like a skew transform and reads as
// a graphic rather than as liquid.
//
// THE SURFACE IS NOT A LINE. It is a soft threshold over a tenth of the disc,
// torn by a travelling one-dimensional fBm that rides along WITH the body (its
// phase carries x), so the ripples belong to the water instead of sliding across
// it. Above it there is a thin mist that decays over a sixth of the disc, which
// is not decoration: it is what keeps the upper cap from being dead ink and
// stops the whole thing reading as a fill gauge.
//
// THE FOAM IS THE ONLY BRIGHTNESS IN THE PACK TIED TO A RHYTHM, and it is tied
// to a physical one. Water throws light off its surface when it is moving and
// goes glassy at the turn, so the crest rides |v| with a floor of 0.30. That is
// the wash being visible in a single frame, not a pulse: the ceiling never
// moves, only the crest, and only because the water is going somewhere.
//
//   c0 reach   how far the body travels
//   c1 lean    how steeply the surface tilts at the turn
//   c2 foam    how much light the moving crest throws
//   c3 period  the there-and-back time, 10 s at 0 down to 4 s at 1
[[ stitchable ]] half4 ml_tide(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float reach = clamp(c0, 0.0, 1.0);
    float lean = clamp(c1, 0.0, 1.0);
    float foam = clamp(c2, 0.0, 1.0);
    float per = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    float P = mix(10.0, 4.0, per);
    float w = 6.2831853 / P;
    float ph = w * T;
    // THE TIC: THE BIG ONE. Every so often a wash comes in taller than the rest:
    // the body throws further across and the surface stands higher while it
    // passes. Both are form, and the level is the honest place to put it,
    // because a bigger wave is more water arriving and not the same water lit
    // harder. Sway is pos/A, so scaling A leaves the LEAN untouched and only the
    // travel grows, which is what one big set does.
    float2 tic = ml_tic(T + 3.1, 19.0, 2.8);
    // Responding throws further and leans harder. Both are amplitudes, not
    // rates, so the wash keeps its phase and simply commits to it.
    float A = (0.16 + 0.30 * reach) * (1.0 + 0.30 * tic.x + 0.28 * st.drive);
    float pos = -A * cos(ph);              // position: the integral of the speed
    float vel = sin(ph);                   // normalised speed, +1 crossing right
    float sway = pos / max(A, 1e-4);       // -1..1, which side the weight is on

    // The surface. uv.y grows DOWNWARD, so positive `below` is under water.
    // The base level sits a little above centre so the water is most of the
    // disc: a body of light with a lit surface, not a half-filled circle.
    float ripple = 0.030 * S * ml_fbm1((uv.x - pos) * 2.4 / S + 0.49 * T, 3, 5.0);
    float h = -0.080 + 0.55 * lean * (1.0 + 0.40 * st.drive) * sway * uv.x
           + ripple - 0.070 * tic.x;
    float below = uv.y - h;

    float f = 4.1 / S;
    // The lean is in the material too: the body shears with depth the way a
    // column of water does when the whole bowl is tipped.
    float3 dom = float3((uv.x - pos - 0.30 * lean * sway * below) * f,
                        uv.y * f * 0.90, 0.070 * T);
    float n = ml_fbm3(dom, 3, 2.03, 0.5);

    float body = smoothstep(-0.045, 0.075, below);
    // The light lives near the surface and is extinguished with depth, Beer's
    // law with a fifth of the disc as its length. The first cut had the mass
    // getting BRIGHTER downward, on the theory that deeper is denser, and the
    // result was an evenly lit half-disc that read as a battery at half charge.
    // Falling off into the dark under the surface is what makes it a wash: the
    // eye follows the lit layer leaning, and the bowl has no bottom to measure.
    float weight = 0.30 + 0.70 * exp(-max(below, 0.0) / 0.20);
    float dens = body * weight * (0.30 + 1.05 * saturate(0.5 + 0.95 * n));

    // SUCCESS: the brightest wash this water throws, crossing the way the water
    // crosses. It multiplies the body, so the air above the surface stays air.
    float surge = ml_crest(clamp(uv.x * 1.11 + 0.5, 0.0, 1.0), st, 0.32);
    dens *= 1.0 + 0.85 * surge + 0.14 * st.lift;

    // The crest, straddling the surface and torn by the same field, so no part
    // of it is ever a rule. Gaussian rather than a band: a band has two edges.
    float edge = below - 0.010 - 0.030 * n;
    float crest = exp(-(edge * edge) / (0.042 * 0.042)) * foam * (0.30 + 0.70 * abs(vel));
    // The air over the water. A sixth of the disc of falloff, so the cap above
    // the surface is dim rather than empty.
    float mist = 0.13 * exp(-max(-below, 0.0) / 0.13);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.50 * dens + 0.30 * crest + mist;
    float hot = smoothstep(0.60, 1.00, dens) * 0.40 + crest * 0.95;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 4. Undertow

// UNDERTOW. Two layers sliding opposite ways, and what is drawn is neither.
//
// THE IDEA, which is the whole species. Two sheets of the same material are
// advected in opposite directions across the disc. Adding them together would
// give a wash going nowhere. Instead the picture is the SEAM: the set of places
// where the two sheets happen to read the same value. That set is a braid of
// filaments, it is dense where the two are similar and sparse where they are
// not, and it moves in NEITHER direction, because it belongs to both sheets at
// once. Watch it and you cannot say which way it is going, which is exactly what
// it feels like to stand in one.
//
//   d = na - nb
//   seam = w^2 / (w^2 + d^2)
//
// A Lorentzian rather than a threshold on |d|. It has no edge at any width: it
// falls off forever instead of stopping, which is what an isoline of a smooth
// field should look like when it is made of liquid rather than drawn with a pen.
// `contrast` sets w, so turning it up narrows the braid and turning it down
// broadens it into a haze, and neither end has a hard value in it.
//
// THE BRAID IS GATED BY THE OVERLAP of the two layer masks, 4 m (1 - m), which
// is 1 exactly on the interface and 0 where one layer has the frame to itself.
// So the disc reads as mass above, mass below, and structure born in the band
// between them: three things, which is one more than a shear usually gives you
// and the reason this holds up at 300 pt.
//
// THE SLIP IS THE FASTEST CARRIER IN THE PACK, and it can afford to be. What the
// eye follows here is the SEAM, and the seam does not travel: it is an
// interference pattern between two sheets, so doubling the slip makes the braid
// turn over twice as fast in place rather than sliding twice as fast across.
// That is the one style in the set where speed buys activity with no risk of the
// thing a thinking indicator must never look like, which is scrolling.
//
//   c0 contrast   how tight the seam is against how present the veil is
//   c1 slip       the differential speed of the two sheets
//   c2 veil       how much of the two sheets themselves is visible at all
//   c3 bias       where the interface sits: 0.5 through the centre, 0 and 1 a
//                 quarter of the disc up or down, and it always breathes a
//                 little on a ninety second period so it is never a rule
[[ stitchable ]] half4 ml_undertow(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float contrast = clamp(c0, 0.0, 1.0);
    float slip = clamp(c1, 0.0, 1.0);
    float veil = clamp(c2, 0.0, 1.0);
    float bias = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    float iface = 0.52 * (bias - 0.5) + 0.030 * sin(T * 0.099);
    float sfrac = (uv.y - iface) / 0.24;
    float mUp = 1.0 - smoothstep(-1.0, 1.0, sfrac);
    float overlap = 4.0 * mUp * (1.0 - mUp);

    float u = 0.030 + 0.095 * slip;
    float f = 3.6 / S;

    // THE TIC: THE SHEAR KICK. The two sheets take one extra step past each
    // other and come back. Nothing about the sheets changes and nothing about
    // the light does: it is a bounded offset on the two advections, equal and
    // opposite, so what the eye actually sees is the SEAM churning harder for a
    // couple of seconds and then settling. The braid is an interference pattern,
    // and interference reacts to relative motion far more than to speed.
    float2 tic = ml_tic(T + 4.4, 29.0, 2.2);
    float kick = tic.x * 0.090;
    // Two sheets of the same material at slightly different scales and different
    // corners of the noise domain, so they are two sheets and not one sheet
    // sampled twice.
    // THE LAYERS ARE DRAWN OUT INTO STREAKS, and this is the motion fix. The
    // seam was the whole picture, and a seam is an interference pattern: it
    // does not travel, it only reshuffles. So the honest description of this
    // style was "it kind of shifts around" while its NAME promised two layers
    // sliding, and nothing on screen was sliding at all.
    //
    // The sheets are drawn out along the slide so each one has a direction, and
    // then NOT drawn out any further, which is the part that took a measurement
    // to find. The first attempt stretched them four or five to one, and the
    // style promptly became the slowest thing in the pack: a long horizontal
    // streak sliding horizontally looks the same at every instant, so there is
    // nothing for the eye to track. That is the aperture problem, and it is the
    // exact opposite of legible motion, arrived at by trying too hard for it.
    //
    // Just under two to one is the sweet spot: enough elongation to say which
    // way the sheet runs, enough variation along the length to see it go. The
    // top half's forms run right, the bottom half's run left, and either one can
    // be followed. TWO OCTAVES, not three: the per-octave rotation would scramble
    // the anisotropy doing the work, the lesson the glaze's shattered fronts
    // already taught this file once.
    float3 qa = float3((uv.x - u * T - kick - 0.75 * u * st.push) * f * 0.62,
                       uv.y * f * 1.15,  2.0 + 0.060 * T);
    float3 qb = float3((uv.x + u * T + kick + 0.75 * u * st.push) * f * 0.66,
                       uv.y * f * 1.07, 23.0 + 0.054 * T);
    float na = ml_fbm3(qa, 2, 2.03, 0.5);
    float nb = ml_fbm3(qb, 2, 2.03, 0.5);

    float d = na - nb;
    // The width is generous, and that is the correction that made this liquid.
    // The first cut ran a tenth of this and drew hairlines: bright wires
    // crossing a dark disc, which is lightning, not water. na - nb has a spread
    // of about half a unit, so a width of 0.16 makes the seam a BAND about a
    // third of that spread wide, which is a braid of soft channels rather than a
    // wire diagram. Contrast still tightens it, but it can no longer reach a
    // width where the material has an edge.
    float wid = 0.075 + 0.170 * (1.0 - contrast);
    float seam = (wid * wid) / (wid * wid + d * d);

    float base = mUp * (0.5 + 0.95 * na) + (1.0 - mUp) * (0.5 + 0.95 * nb);
    base = smoothstep(0.22 + 0.09 * st.drive, 0.95 - 0.09 * st.drive, base);

    // SUCCESS: the surge runs the way the top sheet runs.
    float crest = ml_crest(clamp(uv.x * 1.11 + 0.5, 0.0, 1.0), st, 0.32);
    base *= 1.0 + 1.90 * crest + 0.22 * st.lift;

    float braid = seam * overlap * (0.30 + 0.55 * contrast);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    // The two sheets carry more of the picture than they did, so the braid has
    // mass on both sides of it to be born between rather than a void.
    // The sheets now carry the picture and the braid trims it, where it used to
    // be the other way round. That is the same rebalance in the light that the
    // streaks are in the geometry: you cannot read two layers sliding if what
    // you are looking at is mostly the thing between them.
    float t = 0.045 + (0.30 + 0.44 * veil) * base + 0.24 * braid;
    // THE WALK IS CAPPED BELOW THE PALE STOP, and this is the pour pack's
    // pv_tint lesson arriving a second time. Of the species here this one keeps
    // the most of its area near the tone, so the braid's peaks were the only
    // places in the pack routinely crossing 0.78 into the specular segment,
    // where the rail halves its chroma on the way to a pale highlight. The
    // result was a grey-white tangle sitting next to five warm neighbours in the
    // gallery. Kneed rather than clamped, so the top of the range compresses
    // toward 0.77 instead of flattening onto it and drawing a contour.
    t = 0.77 * ml_knee(t / 0.77, 0.70);
    float hot = braid * 0.50 + smoothstep(0.74, 1.00, base) * 0.18;
    // Emitting at 0.80, not the pack's usual 0.88: on a field already sitting at
    // the tone, pale light does not read as hotter amber, it reads as grey.
    return ml_write(pal, inkLin, t, hot, 0.80, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 5. Meander

// MEANDER. One bright channel wandering through dark ground. The path is the
// thought.
//
// THE CENTRELINE is a one-dimensional fBm in x, drifting slowly in its own
// argument so the river re-cuts itself over a minute or so rather than holding a
// shape. Three taps of it a pixel: the value, and one on each side. The two
// neighbours are there for the SLOPE, and the slope earns its cost. Distance to
// a curve measured straight down the y axis is not distance to the curve; it is
// distance divided by the cosine of the bank angle, so a channel drawn that way
// fattens wherever the river turns, which is precisely where a real one narrows.
// Dividing by sqrt(1 + slope^2) is the correction, and without it the meander
// reads as a fat lazy ribbon instead of as water finding a way through.
//
// THE LIGHT INSIDE IT TRAVELS. The channel's own material is a field sampled in
// channel coordinates (along the river, across it) and advected along, so the
// bright and dim stretches slide downstream while the banks stay put. That is
// the difference between a river and a drawn line: the line is where the water
// is, the water is not the line.
//
// TWO GAUSSIANS, not one, and this is the pack's only real spatial bloom.
// exp(-1.55 u^2) is the water; exp(-0.30 u^2) is its light in the air above it,
// two and a quarter times as wide and an eighth as bright. Both are closed form,
// so the halo costs two exponentials rather than eleven taps of the field.
//
// THE BANKS ARE CUT DARK, which is the thing that makes it read as a channel
// rather than as a glowing stroke. A dim ring just outside the water pushes the
// ground back toward ink, so the river sits IN something. Ground that simply got
// darker with distance would read as a vignette; a lip at a fixed distance from
// the water reads as an edge the water made.
//
//   c0 width    the channel's half width
//   c1 wander   how far the path strays from straight
//   c2 bank     how deep the cut on either side is
//   c3 flow     how fast the light travels down it
[[ stitchable ]] half4 ml_meander(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float width = clamp(c0, 0.0, 1.0);
    float wander = clamp(c1, 0.0, 1.0);
    float bank = clamp(c2, 0.0, 1.0);
    float flow = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    float xa = uv.x / S;
    // THE TIC: THE OXBOW. The channel swings a wider loop and eases back. The
    // throw grows and the path slides at the same time, so it is not a shape
    // being scaled in place: the river reaches out, finds a longer way round,
    // and returns to the line it was on. Both terms are on the centreline, which
    // means the slope, the width normal and the water inside all follow for
    // free, the way they do when a real channel migrates.
    float2 tic = ml_tic(T + 2.2, 37.0, 3.0);
    float pth = 0.049 * T + 0.065 * tic.x;    // the river re-cuts itself, slowly
    const float PF = 1.15;                    // the path's pitch, in xa
    const float DX = 0.055;                   // the slope's half step, in xa

    // THE WANDER IS DOMAIN DRIFT, NOT JITTER, and that distinction is the whole
    // fix. Three fBm octaves at a pitch of 3.2 gave the disc three bends with
    // kinks between them, and three bends with kinks is a seismograph trace.
    // Read as an EQ meter it is not merely wrong, it is a banned shape.
    //
    // So the path is ONE smooth value-noise arc at a pitch of 1.15, which is
    // about one cell across the whole disc: a single broad curve, sometimes a C,
    // sometimes a lazy S, never a zigzag. The second term is a quarter-weight
    // whisper at twice the pitch, enough that the arc is not a parabola. All the
    // CHANGE comes from `pth` sliding the domain underneath at a fortieth of a
    // cell a second, so the river re-cuts itself over about twenty seconds
    // without ever moving fast enough to watch. Slow domain drift, not per-x
    // detail: the same amount of life, none of the graph.
    float w0 = ml_vnoise1(xa * PF + pth, 7.0)
             + 0.24 * ml_vnoise1(xa * PF * 2.3 + pth * 1.4, 23.0);
    float wA = ml_vnoise1((xa - DX) * PF + pth, 7.0)
             + 0.24 * ml_vnoise1((xa - DX) * PF * 2.3 + pth * 1.4, 23.0);
    float wB = ml_vnoise1((xa + DX) * PF + pth, 7.0)
             + 0.24 * ml_vnoise1((xa + DX) * PF * 2.3 + pth * 1.4, 23.0);

    float amp = (0.13 + 0.22 * wander) * (1.0 + 0.38 * tic.x);
    float yc = amp * w0;
    float slope = amp * (wB - wA) / (2.0 * DX) / S;
    float dist = (uv.y - yc) / sqrt(1.0 + slope * slope);

    // The width breathes along the length. A channel of constant width is a
    // pipe; rivers pool and pinch. The pitch of the breathing came down with the
    // path's, for the same reason: at 3.2 the pinches were close enough together
    // to read as teeth.
    float wv = (0.055 + 0.085 * width) * S * (1.0 - 0.16 * st.drive);
    wv *= 0.80 + 0.36 * (0.5 + 0.5 * ml_vnoise1(xa * 1.5 + 3.3, 19.0));
    float uu = dist / max(wv, 1e-4);

    // The light runs faster down the channel than it did. The arc re-cutting is
    // this style's slowest motion and its most obvious one, which left the verb
    // reading as "it wanders" when it should read as "it FLOWS": the wandering
    // is the shape, the flowing is the subject. Responding adds its urgency as a
    // distance, so the water speeds up from where it already was.
    float travel = (0.50 + 1.30 * flow) * T + (0.75 + 1.20 * flow) * st.push;
    // The cross-channel coordinate is CLAMPED before it goes into the water
    // field, and that clamp is not tidiness. uu grows without bound away from
    // the centreline, so an unclamped sample makes the width modulation below a
    // function of how far out you are, and the channel grows feathers: vertical
    // streaks combed out of it at every bend. Two channel widths of cross
    // variation is all the water has; past that it is the same water.
    float3 qf = float3(xa * 3.4 - travel, clamp(uu, -2.0, 2.0) * 0.42, 4.0 + 0.042 * T);
    float water = saturate(0.45 + 0.95 * ml_fbm3(qf, 3, 2.03, 0.5));

    // SUCCESS: a bright head runs the length of the channel, the way a release
    // upstream actually arrives.
    float surge = ml_crest(clamp(uv.x * 1.11 + 0.5, 0.0, 1.0), st, 0.26);
    // The surge widens the channel as well as lighting it, because `water` is a
    // saturating term and brightness alone runs out of room: a flood is more
    // water, not the same water shining harder.
    water = saturate(water * (1.0 + 2.4 * surge) + 0.20 * st.lift);

    // The water swells and pinches the channel it is in, so the SILHOUETTE
    // moves with the flow and not just the brightness inside a fixed outline.
    // Without this the meander is a stroke with a texture painted on it, which
    // is what the first render was and what a drawn line would have been. The
    // range is gentler than it was: a channel whose width swings by half its own
    // size grows vertical combs where the path is steep.
    float k = uu / (0.78 + 0.44 * water + 0.55 * surge);
    float g1 = exp(-1.55 * k * k);            // the water
    float g2 = exp(-0.30 * k * k);            // its light in the air

    // The ground. Two octaves is enough: it is meant to have form at 300 pt and
    // to be invisible at 20, and a third octave only buys noise at both.
    float3 qm = float3(uv.x * 2.6 / S, uv.y * 2.6 / S, 30.0 + 0.063 * T);
    float ground = smoothstep(0.25, 0.95, 0.5 + 1.0 * ml_fbm3(qm, 2, 2.03, 0.5));

    // THE BANKS ARE SHOULDERS, NOT A RING. The first cut used a tight Gaussian
    // at a fixed distance and drew a dark outline around the water, which is a
    // stroke with a keyline: exactly the graphic reading this style has to lose.
    // A standard deviation of about one whole channel width instead makes the
    // ground fall away either side of the river and come back, which is what a
    // cut bank looks like from above and has no edge anywhere in it.
    float lip = abs(uu) - 1.90;
    float cut = 1.0 - 0.55 * bank * exp(-0.42 * lip * lip);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.20 * ground * cut + g1 * (0.12 + 0.38 * water) + g2 * (0.05 + 0.07 * water);
    float hot = g1 * (0.20 + 0.80 * water) * 0.70;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 6. Confluence

/// THE JOIN LAW. The pv_exhale_law pattern, and the same argument for it: state
/// the MOTION as a law and take the position as that law's exact integral, so no
/// frame has to remember the last one. Sample at any t at all, from a screenshot
/// rig, a scrubbed slider or an app resumed from the background, and the flows
/// are exactly where the animation would have put them.
///
///   v(tau) = hold + (1 - hold) e^(-k tau),   k = 3 / joinTime
///   D(tau) = hold tau + (1 - hold) (1 - e^(-k tau)) / k
///
/// k = 3 / joinTime rather than 1 / joinTime so the dial means what it says: at
/// tau = joinTime the approach is within five per cent of the hold, which is the
/// instant a person would call it joined.
///
/// HOLD IS 0.26, not the exhale's 0.055, and the difference is the species. A
/// breath that has been let out is nearly still and should be. A river that has
/// taken in another river is a bigger river: it is going somewhere at the end,
/// so the rest state here keeps about a quarter of its arrival speed forever,
/// and the joined channel's light still moves down it.
///
/// It was a sixth, and a sixth measured out at about one code value of change a
/// second across the disc, which is a whisper nobody can hear. This style spends
/// almost all of its life settled: it reaches the hold in under four seconds and
/// then a person waits on it. A settle state that cannot be seen to move is not
/// a settle state, it is a freeze with a good excuse, and the whole point of an
/// indicator is that work is visibly happening. Returns (v, D, e), where e is
/// the fraction of the approach still to run.
static inline float3 ml_join_law(float tau, float joinTime) {
    const float HOLD = 0.26;
    float E = max(joinTime, 0.50);
    float k = 3.0 / E;
    float e = exp(-k * max(tau, 0.0));
    float v = HOLD + (1.0 - HOLD) * e;
    float D = HOLD * max(tau, 0.0) + (1.0 - HOLD) * (1.0 - e) / k;
    return float3(v, D, e);
}

// CONFLUENCE. Two flows finding each other, and joined is the rest state.
//
// THE ARC. Everything that arrives rides `e`, the fraction of the approach still
// to run, and everything that keeps going rides `D`, the distance travelled.
// Three things arrive:
//
//   the separation    the arms start (0.055 + 0.15 approach) apart at the
//                     meeting and close to 0.020, which is not zero. Two rivers
//                     that have joined still have a line between them for a
//                     while; a separation that went to zero would make the
//                     rest state one channel with no memory of being two, and
//                     the memory is the point.
//   the meeting       the junction slides upstream, from a quarter of the disc
//                     right of centre to just left of it. At birth the disc is
//                     mostly two arms with a join in the corner; at rest it is
//                     mostly one flow with a fork at its left edge. That is the
//                     arc a person actually reads.
//   the tempo         the light down the channel starts at six times its
//                     resting speed and settles. The arrival is legible in a
//                     SINGLE FRAME, not only in motion: photograph it at one
//                     second and at twelve and the two are different pictures,
//                     not the same picture at two offsets.
//
// One thing does not arrive: D keeps growing at the hold rate forever, so the
// joined river is still a river a minute later. Settled is a whisper of motion,
// never a freeze.
//
// THE BRAID IS FREE. Each arm carries its own small wander on its own noise
// lane. Downstream of the junction both centrelines land on the same axis, so
// what is left of them is two wanders of about a thirtieth of the disc crossing
// and re-crossing inside one channel. Nothing draws a braid; the braid is what
// two paths that have agreed on a direction but not on a route do.
//
// THE TWO CHANNELS COMBINE AS A + B - AB, not A + B. Where they coincide, a sum
// counts the same water twice and the join is a hot bar exactly where the
// picture should be calmest. The soft union caps at one and leaves the junction
// looking like more water rather than like more light.
//
//   c0 approach   how far apart the flows start
//   c1 mingle     how much the two waters interleave once joined
//   c2 shimmer    fine surface texture travelling with the flow
//   c3 angle      the fork's spread, from nearly parallel to a wide Y
[[ stitchable ]] half4 ml_confluence(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float approach = clamp(c0, 0.0, 1.0);
    float mingle = clamp(c1, 0.0, 1.0);
    float shimmer = clamp(c2, 0.0, 1.0);
    float angleK = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    // The law runs on real seconds: 3.6 is about as long as a person waits for two
    // things to become one thing without wondering whether it is stuck.
    float tau = max(time - epoch, 0.0);
    float3 law = ml_join_law(tau, 3.6);
    float e = law.z;
    float travel = law.y * 1.53 * max(speed, 0.0) + 1.20 * st.push;

    // THE JOINED FLOW LEAVES ALONG ITS OWN HEADING. Built on the frame's x axis
    // this style settled into a horizontal band, which is a silhouette three
    // other species in the roster already own, and a confluence that ends up
    // looking like everything else has no identity left. So the whole figure is
    // constructed in a rotated frame: `o` is the outflow's heading, a quarter
    // radian below horizontal, and the junction sits up and back from the middle
    // of the disc. The composition is then lopsided in both axes at every moment
    // of the arc, which is the only reliable way a circle full of soft light
    // stays recognisable at cell size.
    const float OUT = 0.42;
    float2 o = float2(cos(OUT), sin(OUT));
    float2 nrm = float2(-o.y, o.x);
    float2 qv = uv - float2(-0.10, -0.07);
    float sAx = dot(qv, o);                      // along the outflow
    float nAx = dot(qv, nrm);                    // across it

    // The FORK ITSELF closes, and that is what makes the arc legible. The first
    // cut moved only the separation at the meeting and the meeting's position,
    // and both are small next to the arms' spread, so birth and rest were the
    // same picture a few points apart. Swinging the spread means the shape goes
    // from a wide Y to a single flow with a taper behind it. It closes to 45 per
    // cent and not to nothing: joined is the rest state, but a confluence that
    // forgets it was ever two rivers is just a river.
    // THE TIC: THE SURGE. A pulse of water comes down ONE arm, chosen fresh each
    // time by the tic's own hash, so it is never the same side twice running.
    // That arm swells while the surge passes and the turbulence at the meeting
    // spreads with it, then both settle. Two flows that always contribute
    // equally are a diagram; rivers take turns.
    float2 tic = ml_tic(T + 5.3, 43.0, 2.5);
    float armB = step(0.5, tic.y);

    // Responding closes the fork further: the two flows commit to being one.
    float spread = mix(0.14, 0.55, angleK) * (0.45 + 0.55 * e) * (1.0 - 0.32 * st.drive);
    float sep = 0.018 + (0.030 + 0.120 * approach) * e;
    float sj = 0.22 * e;                         // the meeting, sliding upstream
    float conv = 1.0 - smoothstep(sj - 0.26, sj + 0.14, sAx);
    float su = max(sj - sAx, 0.0);               // how far upstream of it we are

    // The arms wander. Straight arms are a glyph; the wander is under one
    // channel width so downstream the two paths weave INSIDE the joined channel
    // instead of separating back out into two.
    // The pitch is 4.5 because across a disc 0.9 wide anything lower is a
    // constant offset wearing a noise function's name, and two arms offset by a
    // constant are two straight lines.
    float wig = 0.038 * S;
    float armN = (sep + spread * su) * conv;
    float cA = -armN + wig * ml_fbm1(sAx * 4.5 / S - travel * 0.55, 2, 13.0);
    float cB =  armN + wig * ml_fbm1(sAx * 4.5 / S - travel * 0.55, 2, 47.0);

    // The joined channel is wider than either arm, because it is carrying both,
    // and each arm breathes on its own lane. The two are NOT twins: B runs about
    // a fifth wider, because two identical inflows read as a mirrored diagram
    // and no two rivers are the same size.
    float wBase = 0.040 * S * (1.0 + 0.50 * (1.0 - conv));
    float wvA = wBase * (1.0 + 0.72 * tic.x * (1.0 - armB))
             * (0.90 + 0.44 * (0.5 + 0.5 * ml_vnoise1(sAx * 2.6 / S - travel * 0.5, 63.0)));
    float wvB = wBase * 1.18 * (1.0 + 0.72 * tic.x * armB)
              * (0.90 + 0.44 * (0.5 + 0.5 * ml_vnoise1(sAx * 2.6 / S - travel * 0.5 + 5.7, 71.0)));
    float ua = (nAx - cA) / max(wvA, 1e-4);
    float ub = (nAx - cB) / max(wvB, 1e-4);

    // Clamped across, for the meander's reason: an unbounded cross coordinate
    // combs feathers out of the channel wherever it turns. The pitch along is
    // 4.8 and not 7: at 7 the water broke into a row of separate bright beads
    // down the channel, and this family does not do dots under any name.
    float3 qA = float3(sAx * 4.8 / S - travel, clamp(ua, -2.0, 2.0) * 0.45,  3.0);
    float3 qB = float3(sAx * 4.8 / S - travel, clamp(ub, -2.0, 2.0) * 0.45, 26.0);
    float wA = saturate(0.45 + 0.95 * ml_fbm3(qA, 3, 2.03, 0.5));
    float wB = saturate(0.45 + 0.95 * ml_fbm3(qB, 3, 2.03, 0.5));

    // Each arm's own water swells and pinches it, the meander's correction for
    // the same failure: a channel whose outline never moves is a stroke.
    float ka = ua / (0.78 + 0.44 * wA), kb = ub / (0.78 + 0.44 * wB);
    float gA1 = exp(-1.45 * ka * ka), gA2 = exp(-0.28 * ka * ka);
    float gB1 = exp(-1.45 * kb * kb), gB2 = exp(-0.28 * kb * kb);

    // The lacing. A slow scalar travelling downstream decides which water is on
    // top at each point along the joined channel, and it only applies where the
    // channel IS joined: upstream each arm is entirely its own.
    float lace = clamp(0.5 + 0.55 * ml_vnoise1(sAx * 4.2 / S - travel * 0.8, 41.0), 0.0, 1.0);
    float sA = mix(0.5, mix(0.5, lace, mingle), 1.0 - conv);

    float lightA = gA1 * (0.14 + 0.46 * wA) * (0.70 + 0.60 * sA);
    float lightB = gB1 * (0.14 + 0.46 * wB) * (0.70 + 0.60 * (1.0 - sA));
    float chan = lightA + lightB - lightA * lightB;      // soft union, not a sum

    // SUCCESS: the surge comes down the joined channel, from the fork out.
    float surge = ml_crest(clamp(sAx * 1.15 + 0.42, 0.0, 1.0), st, 0.28);
    chan = saturate(chan * (1.0 + 2.3 * surge) + 0.16 * st.lift * chan);

    // THE MEETING IS ALIVE. The shimmer used to be spread down the whole channel,
    // where it was a texture nobody could locate. Gathered into the junction it
    // is the one place in the composition where something is happening: two
    // waters at different speeds arriving at the same water and turning over. It
    // travels with the flow, so it reads as disturbance and not as glitter, and
    // it walks upstream with `sj` as the arc runs.
    float ds = sAx - sj;
    float mw = 0.085 * (1.0 + 0.75 * tic.x);
    float meet = exp(-(ds * ds) / (mw * mw)) * exp(-(nAx * nAx) / (0.075 * 0.075));
    float shN = ml_noise3(float3(sAx * 7.0 / S - travel * 1.9, nAx * 7.0 / S, 0.40 * travel));
    float churnUp = (0.10 + 0.30 * shimmer) * meet * (0.45 + 0.55 * (0.5 + 0.5 * shN));

    float3 qh = float3(uv.x * 2.4 / S, uv.y * 2.4 / S, 40.0 + 0.049 * T);
    float haze = smoothstep(0.28, 0.96, 0.5 + 1.0 * ml_fbm3(qh, 2, 2.03, 0.5));

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.12 * haze + 0.58 * chan + 0.05 * (gA2 + gB2) + churnUp;
    float hot = chan * chan * 0.90 + churnUp * 0.80;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 7. Melt

// MELT. A heavy molten mass, softening and reforming under its own heat.
//
// THE SILHOUETTE IS THE SPECIES, and it is the one shape the other six do not
// own. Every style before this fills its disc: a spiral across the whole of it,
// a body under a level, a band, an arc, a fork. This one is a LUMP. A compact
// closed form sitting in ink with a lot of dark around it, and what it does is
// change shape. Nothing else in the pack has an outline you could trace.
//
// SO THE BODY IS AN IMPLICIT SURFACE, not a threshold on noise. Four Gaussian
// lobes summed and cut at a level: the body, and three drips. Summing before
// cutting is the whole reason this reads as one viscous material rather than as
// four things near each other, because where two lobes overlap the sum crosses
// the level in the space BETWEEN them and draws a neck. Pull a lobe away and the
// neck thins, stretches and finally lets go, and it does all of that for free,
// out of the arithmetic, the way real surface tension does. It is also the
// reason this can have drips at all without breaking the family's oldest rule:
// a drip here is never a circle sitting on its own, it is a swelling of one
// body that is always on its way back in.
//
// NOTHING IS LOST AND NOTHING FALLS. Each drip runs a cycle: pushed out over
// about seven tenths of it, drawn back in over the other three, so the reach is
// slow and the return is more than twice as quick, which is what weight looks
// like. It never leaves the frame and it never detaches. When it lands, the body
// RINGS: exp(-5.5 ph) sin(16 ph), a damped oscillation starting at the instant
// of absorption and gone about half a cycle later. That ring is the whole
// argument for the style. Iron that swallowed a drip should wobble.
//
// A CRUST WITH HOT CRACKS. Molten iron is not lit like water: the skin is the
// coolest part of it and the light comes from inside, through the places where
// the crust has opened. So the shading runs the other way from the rest of the
// pack. Depth into the mass sets a dull base glow, and a separate fBm read in
// the mass's own warped frame supplies the veins, which are the only genuinely
// bright thing here. The surface itself stays dark, and the mass wears a heat
// aura made from the same lobes at two and a half times their radius, so the
// disc around it is warm rather than dead.
//
// TIME ENTERS AS A WARP. The mass writhes because the coordinate it is measured
// in writhes: two octaves of fBm displacing the position before the lobes are
// evaluated at all. Turn the heat up and the displacement grows, which is the
// honest way for a material to get more fluid.
//
//   c0 mass         how much iron there is
//   c1 viscosity    how slowly it moves, and how fat a neck it holds before it
//                   lets go. Default 0.6, thicker than the middle, because this
//                   is the heavy one in the family and it should feel it
//   c2 dripAbsorb   how far a drip reaches, and how hard the body rings when it
//                   comes home
//   c3 heat         how far the crust has opened: the writhe and the veins
[[ stitchable ]] half4 ml_melt(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float massK = clamp(c0, 0.0, 1.0);
    float visc = clamp(c1, 0.0, 1.0);
    float absorb = clamp(c2, 0.0, 1.0);
    float heat = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    // Viscosity is a clock. Iron at temperature moves at a rate its own
    // thickness sets, so one dial slows every motion in the style together
    // rather than each of them separately.
    float rate = mix(1.45, 0.62, visc);

    // THE TIC: THE HEAVY ONE. One drip, picked fresh each time, goes out heavier
    // than its siblings: it reaches half again as far and stays fatter as it
    // stretches, so its neck hangs longer before the body wins. The body is also
    // more willing to move while the tic runs, which is what makes the swell
    // when that mass comes home deeper than the ordinary ones. Weight is the
    // character of this species, and this is the material showing off about it.
    float2 tic = ml_tic(T + 0.9, 53.0, 3.2);
    float heavyIdx = min(floor(tic.y * 3.0), 2.0);

    // THE WRITHE, SLOWED TO A THIRD. This was the wobble. A surface squirming
    // continuously under a body whose real event is the drip cycle gives an eye
    // nothing to hold: both motions are always running, so neither is the
    // subject, and the honest description of the style became "it kind of
    // shifts around". Weight means one thing happening at a time. The skin now
    // creeps, the DRIP is the event, and the mass reads as heavy because heavy
    // things do not fidget between moves.
    float2 wq = uv * (2.4 / S);
    float wz = 70.0 + 0.075 * rate * T;
    float w1 = ml_fbm3(float3(wq, wz), 2, 2.03, 0.5);
    float w2 = ml_fbm3(float3(wq + float2(5.3, -2.1), wz + 17.0), 2, 2.03, 0.5);
    // The writhe grows with the tic as well as with the heat, and that is not
    // decoration: `heavy` scales a drip's REACH, so a tic that lands while the
    // chosen drip happens to be retracted does nothing at all, and half the
    // gestures were invisible. The body working harder is the part of the heave
    // that always shows.
    float2 p = uv + float2(w1, w2) * ((0.055 + 0.085 * heat) * (1.0 + 0.55 * tic.x)) * S;

    // The body's radius, and it is set against the drip's reach below rather
    // than chosen on its own. The first cut had the reach at two thirds of R,
    // which means every drip lived entirely INSIDE the body and no neck ever
    // formed: the whole mechanism was running and none of it was visible. The
    // reach has to clear R by about a third for the sum to cross its level in
    // the gap and draw the neck that is the point of the style.
    float R = (0.165 + 0.075 * massK) * S;

    // The drips, and the ring the body makes when it takes one back.
    float ring = 0.0;
    float lobes = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        // Responding hurries the cycle by shifting its argument, never by
        // scaling its rate: fract() of a rescaled clock would jump.
        float cyc = rate * (T + 1.35 * st.push) * (0.150 + 0.034 * fi) + fi * 0.37;
        float ph = fract(cyc);
        // Out over seven tenths, back over three: slow reach, quick return.
        float g = (ph < 0.70) ? smoothstep(0.0, 1.0, ph / 0.70)
                              : 1.0 - smoothstep(0.0, 1.0, (ph - 0.70) / 0.30);
        // The absorption ring, measured from the instant of landing. Both ends
        // of the cycle sit at zero, so the wrap is silent.
        ring += exp(-5.5 * ph) * sin(16.0 * ph);

        // A new heading each cycle. floor(cyc) jumps, but it jumps at exactly
        // the phase where g is zero and the drip has no extension, so nothing
        // on screen moves when it does.
        float a = fi * 2.094 + 0.09 * rate * T
                + 2.4 * ml_vnoise1(floor(cyc) * 1.7 + fi * 9.0, 5.0);
        float2 dv = float2(cos(a), sin(a));
        // It thins as it stretches, and a thicker material thins less.
        float heavy = (abs(fi - heavyIdx) < 0.5) ? tic.x : 0.0;
        float rr = R * (0.68 + 0.30 * heavy - 0.24 * g * (1.0 - 0.45 * visc));
        // The reach clears the body by half again, up from a third. A drip that
        // barely clears its own body makes a bulge; one that clears it properly
        // hangs off a neck, and the neck is the thing that reads as weight.
        float2 dp = p - dv * ((0.215 + 0.240 * absorb) * S * g * (1.0 + 0.95 * heavy));
        lobes += exp(-dot(dp, dp) / max(rr * rr, 1e-6));
    }

    float Rb = R * (1.0 + (0.09 + 0.20 * absorb) * ring * (1.0 + 1.10 * tic.x));
    float body2 = dot(p, p) / max(Rb * Rb, 1e-6);
    float field = exp(-body2) + lobes;

    // The cut. Below it there is no iron; the crossing is soft over a wide
    // enough span that the skin never has an edge.
    float skin = smoothstep(0.34, 0.62, field);
    float deep = smoothstep(0.34, 1.35, field);      // how far inside we are

    // The heat it gives off. The same lobes at two and a half times their
    // radius, so the aura belongs to the mass's actual shape instead of being a
    // soft circle painted behind it.
    float aura = exp(-body2 / 6.25);

    // THE VEINS, read in the mass's own warped frame so they deform with it.
    float3 qi = float3(p * (3.6 / S), 80.0 + 0.16 * rate * T);
    float vein = smoothstep(0.42, 0.93, 0.5 + 1.05 * ml_fbm3(qi, 3, 2.03, 0.5));
    float cracks = skin * vein * (0.40 + 0.60 * heat) * (0.35 + 0.65 * deep);

    // SUCCESS: the interior glows THROUGH, a bloom that starts at the core and
    // comes out to the skin. It multiplies the cracks and the depth, so the ink
    // around the mass is untouched and the light genuinely comes from inside.
    float surge = ml_crest(clamp(length(p) / (R * 2.3), 0.0, 1.0), st, 0.34);
    cracks *= 1.0 + 6.5 * surge;
    deep = saturate(deep * (1.0 + 1.7 * surge) + 0.18 * st.lift);
    // The heat it throws goes up with the bloom too. This mass occupies a fifth
    // of the disc, so an arrival confined to the iron itself barely moves the
    // picture; letting the aura answer is what makes it read across the circle.
    aura *= 1.0 + 2.6 * surge;

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    // The crust is DARKER than its cracks, which is the whole lighting idea and
    // the opposite of the rest of the pack: here the light is inside the
    // material and only gets out where the skin has opened. Cut the base too
    // generously, as the first pass did, and the mass is a flat orange lump with
    // a few pale marks on it, which is a stone and not molten iron.
    float t = 0.045
            + aura * (0.070 + 0.055 * heat)
            + skin * (0.095 + 0.190 * deep)
            + cracks * 0.33;
    // Capped below the pale stop, the undertow's correction a third time. The
    // veins sit inside a mass that is already near the tone, so unchecked they
    // walk the rail into the specular and the iron comes out cream. Iron does
    // not go cream; it goes yellow-white only at temperatures this style is not
    // depicting, and the emission rail drops to 0.84 for the same reason.
    t = 0.74 * ml_knee(t / 0.74, 0.72);
    float hot = cracks * 0.90;
    return ml_write(pal, inkLin, t, hot, 0.84, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 8. Glaze

// GLAZE. A thin bright film sliding over a dark form, and the light travels in
// the film.
//
// THREE THINGS ARE HAPPENING AT THREE SPEEDS, and the whole style is that
// separation. The form beneath barely moves: two octaves of fBm drifting at a
// fiftieth of a cell a second, dark, there to be a surface with relief and not
// to be looked at. The film slides across it at a quarter of a frame width a
// second. And the light inside the film runs a third again faster than the film
// does, which is the literal reading of the brief and also true: a highlight on
// moving water is not stuck to the water, it is where the slope happens to face
// the light, and it outruns the liquid carrying it.
//
// THE FILM IS A WAVE FRONT, not a stripe. The field is sampled at five times the
// pitch ALONG the travel direction and one and a half times ACROSS it, so its
// forms come out three times longer across the flow than along it: bands, with
// ragged ends and irregular spacing, two or three in the disc at once. A stripe
// would have to be drawn; this is what a noise field looks like when you squash
// it in one direction, which means it can never be evenly spaced and never has
// a hard edge.
//
// THE MENISCUS IS FREE, and it is the sheen. 4 f (1 - f) peaks exactly where the
// film's density crosses one half, which is its EDGE, and falls to nothing both
// in the open water and off the dry side. That is where a real film is
// brightest, because the edge is where the surface curves hardest and catches
// the most light, and it costs one multiply. It also means the bright line is
// always attached to the film's own boundary rather than being a second thing
// travelling near it.
//
// THE FILM POOLS. Its density is biased down by the form's relief, so it runs
// thick in the hollows and thins over the ridges as it passes. That single term
// is what makes this read as liquid ON something rather than a band drawn ACROSS
// something, and it is the reason the form beneath needs relief at all.
//
// WHY IT IS NOT THE TIDE AND NOT THE UNDERTOW. The tide has a LEVEL: a body of
// liquid with a surface and a bowl to sit in. This has no level and no volume,
// only a skin passing over. The undertow is two layers and the picture is their
// seam, which stays where it is; this is ONE film and the picture is its travel.
// The bands run at a steep diagonal for the same reason, so nothing at cell size
// can confuse the two.
//
//   c0 sheet   how much of the form is wet at once
//   c1 slide   how fast the film crosses
//   c2 sheen   the meniscus and the glints travelling inside it
//   c3 tilt    the heading the film runs along, which tips the whole grammar
[[ stitchable ]] half4 ml_glaze(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float sheetK = clamp(c0, 0.0, 1.0);
    float slide = clamp(c1, 0.0, 1.0);
    float sheenK = clamp(c2, 0.0, 1.0);
    float tilt = clamp(c3, 0.0, 1.0);
    MLState st = ml_state(stateIndex, stateTau);

    // THE TIC: THE SLEW. The form tips, the whole grammar leans about eleven
    // degrees, and the film surges a little as it does before both ease back.
    // Rotating the heading rather than nudging the fronts means the bands, the
    // pooling and the sheen all swing together as one sheet on one surface,
    // which is what tipping something glazed actually looks like. A film
    // sloshing when its surface moves is the physics agreeing with the gesture.
    float2 tic = ml_tic(T + 1.3, 61.0, 2.4);
    float th = mix(-1.00, -0.15, tilt) + 0.125 * tic.x;
    float2 dv = float2(cos(th), sin(th));
    float2 ev = float2(-dv.y, dv.x);
    float along = dot(uv, dv);
    float across = dot(uv, ev);

    // THE FORM. Dark, slow, and only ever a surface for something else to run
    // over. Two octaves: it needs relief, not detail.
    float3 qf = float3(uv * (2.3 / S), 60.0 + 0.020 * T);
    float relief = saturate(0.5 + 1.0 * ml_fbm3(qf, 2, 2.03, 0.5));

    // THE FILM, squashed along the travel so its forms are wave fronts.
    // THE SLIDE IS SLOWER THAN IT LOOKS LIKE IT SHOULD BE, and measuring it is
    // the only way to have known. At a fifth of a frame width a second the bands
    // advanced about their OWN WIDTH every second, and a high-contrast pattern
    // moving one period per second is a scroll: measured against its own
    // contrast this style was turning over three times faster than anything else
    // in the pack while every individual number in it looked reasonable. Screen
    // speed is not tempo. What the eye reads is speed divided by feature size,
    // so the fix is both ends: the bands got wider and the slide got slower, and
    // a front now takes about fifteen seconds to cross. The pitch went the other
    // way at the same time, and had to: with only one and a half fronts in the
    // disc the total brightness swung by nearly half as they came and went. Two
    // and a half thinner ones average that out to something steady, and because
    // tempo is speed over feature size, halving both leaves the tempo where it
    // was and only changes what the picture is made of.
    float travel = (0.036 + 0.052 * slide) * T + 0.028 * tic.x
                 + (0.055 + 0.075 * slide) * st.push;
    // TWO OCTAVES, NOT THREE, and the reason is the per-octave rotation. ML_ROT
    // is what stops an fBm growing a plaid, but it also turns each octave's axes
    // relative to the last, so the squash that makes these forms into bands
    // survives the first octave and is scrambled by the third. Cut at three, the
    // film came out as disconnected pale shards: a band broken into flakes,
    // which is peeling paint and not running liquid. Two octaves keeps the
    // anisotropy, and the across pitch drops to 0.7 so barely half a cell spans
    // the disc sideways and a front stays continuous the whole way over.
    // The across pitch is 1.25 and not 0.85 for a reason that only shows up over
    // time. Squashed too hard, every front is uniform along its whole length, so
    // the disc is either wet or dry and its brightness swings by half as the
    // bands pass: that is a luminance pulse, which this family does not do. A
    // little variation along the front means some part of the disc is always
    // carrying film, and the total stays put while the picture keeps moving.
    float3 qs = float3((along - travel) * (5.5 / S), across * (1.25 / S), 40.0 + 0.022 * T);
    // Biased by the relief, so it pools in the hollows and thins on the ridges.
    float wet = 0.5 + 1.15 * ml_fbm3(qs, 2, 2.03, 0.5) - 0.34 * (relief - 0.5);
    // A HIGH cut, and this is the difference between a film and a camouflage
    // pattern. Cut near the middle of the field's range and half the disc is wet
    // at once: broad pale patches with the dry form showing between them, which
    // is marbling and belongs to another pack. Cut in the upper fifth and two or
    // three narrow bands cross a dark form, which is a sheet of liquid running
    // over something.
    // Responding narrows the fronts: fewer, cleaner, more deliberate.
    float cut = mix(0.82, 0.52, sheetK) + 0.030 * st.drive;

    // SUCCESS: the surge runs along the film's own heading, and it arrives as a
    // WAVE OF WETTING rather than as extra light on the film that is already
    // there. Multiplying `film` was the obvious move and it does almost nothing,
    // because film is a smoothstep that spends its life at 0 or at 1: scaling a
    // saturated mask can only touch the sliver in between. Dropping the cut
    // where the crest is lets the front genuinely flood, which is both what more
    // water looks like and the only lever with any range in it.
    float surge = ml_crest(clamp(along * 1.15 + 0.5, 0.0, 1.0), st, 0.30);
    float cutS = cut - 0.34 * surge - 0.05 * st.lift;
    float film = smoothstep(cutS - 0.13, cutS + 0.17, wet);

    // The meniscus: brightest exactly at the film's own boundary.
    float edge = 4.0 * film * (1.0 - film);

    // The light inside it, outrunning it by a third. Stretched across the flow,
    // so these are broad sheens travelling along the front and never anything
    // the eye could call a dot or a sparkle.
    //
    // THE PITCH IS 4.0 AND IT WAS 11, which was the one real mistake in this
    // style. Speed on screen and pitch in the domain are not the same dial: at
    // eleven the sheen crossed four noise cells a second and the whole disc
    // decorrelated in a quarter of a second, which measures as motion and reads
    // as a strobe. It was moving seven times faster than anything else in the
    // pack. Same screen speed, a quarter of the pitch: the light still outruns
    // the film carrying it, and now you can see it do it.
    float gl = ml_noise3(float3((along - travel * 1.30) * (4.0 / S),
                                across * (1.9 / S), 55.0 + 0.045 * T));
    float spec = film * smoothstep(0.38, 0.96, 0.5 + gl);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    // The form is DARK. It is a surface for the film to run over and the eye
    // should never be asked to look at it: lit any higher it stops being the
    // ground and starts competing with the thing sliding across it.
    //
    // But it is never DRY. A glazed thing that has been wet stays damp in its
    // low places, and that one term is doing structural work as well as honest
    // work: without it the disc's total brightness swung by half as the fronts
    // came and went, which is a luminance pulse however aperiodic it is, and
    // this family does not pulse. The residue keeps the hollows lit between
    // fronts, so what changes as the film passes is where the light IS, not how
    // much of it there is.
    float t = 0.045
            + 0.060 + 0.140 * smoothstep(0.18, 0.95, relief)  // the dark form
            + 0.055 * (1.0 - relief)                          // still damp in the hollows
            + film * (0.060 + 0.075 * (1.0 - relief))         // the wet sheet
            + edge * (0.115 + 0.175 * sheenK) * (1.0 + 0.80 * st.drive)  // the meniscus
            + spec * (0.060 + 0.160 * sheenK) * (1.0 + 0.70 * st.drive);
    // Soft-capped below the rail's pale stop, the undertow's correction: a film
    // is the brightest thing this pack draws and it should stay amber doing it.
    t = 0.72 * ml_knee(t / 0.72, 0.72);
    float hot = edge * (0.35 + 0.45 * sheenK) + spec * 0.55;
    return ml_write(pal, inkLin, t, hot, 0.86, glow, ml_bowl(uv), position * pixelScale);
}
