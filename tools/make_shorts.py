"""Records Jingle Jelly Shorts/Reels for parents: a sing-along plays in Godot's
Movie Maker mode with a hook line and an end card, and ffmpeg turns it into a
vertical 1080x1920 MP4 with a caption file next to it. Used by
.github/workflows/shorts.yml.

Run from the repo root (needs godot on PATH, ffmpeg, and a display, e.g. xvfb-run):
  python3 tools/make_shorts.py --out shorts --count 1
Each clip gives <out>/jingle-jelly-<date>-<n>.mp4 and .json (title, caption, hashtags).
"""
import argparse
import datetime
import json
import os
import random
import subprocess

SONGS = {
    "twinkle": "Twinkle Twinkle Little Star", "bus": "The Wheels on the Bus",
    "farm": "Old MacDonald", "baa": "Baa Baa Black Sheep", "boat": "Row Row Row Your Boat",
    "spider": "Itsy Bitsy Spider", "mary": "Mary Had a Little Lamb",
    "body": "Head, Shoulders, Knees and Toes",
}

# Spoken to parents, never to the child.
HOOKS = [
    "Toddler sing-along time!",
    "Screen time that sings along",
    "Words light up as they sing",
    "Tap, sing and giggle",
    "Calm songs for little ones",
]
TITLES = [
    "{song} sing-along for toddlers 🎵 #shorts",
    "{song} with Jelly 💗 nursery rhyme #shorts",
    "Learn {song} with words that light up #shorts",
]
CAPTIONS = [
    "{song} with Jelly 💗 Every word lights up as it's sung, so little ones can follow along.\n"
    "Jingle Jelly has nursery rhymes, bath time and gentle games for toddlers, with a parent lock and no internet needed.\n\n{cta}",
    "Parents: a sing-along your toddler can tap and play with 🎶 {song}, Wheels on the Bus, Old MacDonald and more.\n"
    "Simple, bright and works offline.\n\n{cta}",
]
HASHTAGS = ["#nurseryrhymes", "#toddlers", "#kidssongs", "#parenting", "#toddleractivities",
            "#preschool", "#momlife", "#singalong", "#learningapp", "#shorts"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="shorts")
    ap.add_argument("--godot", default="godot")
    ap.add_argument("--count", type=int, default=1)
    ap.add_argument("--seconds", type=float, default=20.0)
    ap.add_argument("--cta", default="Coming soon on Google Play")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    day = datetime.date.fromisoformat(a.date).toordinal()
    rnd = random.Random(day)
    ids = list(SONGS)
    for n in range(1, a.count + 1):
        song = ids[(day + n) % len(ids)]
        hook = HOOKS[(day + n) % len(HOOKS)]
        name = os.path.join(a.out, f"jingle-jelly-{a.date}-{n}")
        subprocess.run([
            a.godot, "--path", "godot", "--write-movie", name + ".avi", "--fixed-fps", "30",
            "--resolution", "720x1280", "--quit-after", str(int((a.seconds + 10) * 30)),
            "--", "--promo", f"--song={song}", f"--seconds={a.seconds}", f"--hook={hook}", f"--cta={a.cta}",
        ], check=True, stdout=subprocess.DEVNULL)
        subprocess.run([
            "ffmpeg", "-v", "error", "-y", "-i", name + ".avi",
            "-vf", "scale=1080:1920:flags=lanczos,format=yuv420p",
            "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-r", "30",
            "-c:a", "aac", "-b:a", "160k", "-ar", "44100", "-af", "loudnorm=I=-14:TP=-1.5",
            "-movflags", "+faststart", name + ".mp4"], check=True)
        os.remove(name + ".avi")
        fill = {"song": SONGS[song], "cta": a.cta}
        tags = HASHTAGS[:3] + rnd.sample(HASHTAGS[3:], 5)
        with open(name + ".json", "w") as f:
            json.dump({
                "app": "Jingle Jelly", "title": rnd.choice(TITLES).format(**fill),
                "caption": rnd.choice(CAPTIONS).format(**fill) + "\n\n" + " ".join(tags),
                "hashtags": tags, "hook": hook, "song": song,
                # A nursery-rhyme cartoon is child-directed content on YouTube, whoever the caption speaks to.
                "made_for_kids": True,
            }, f, indent=2, ensure_ascii=False)
        print(f"wrote {name}.mp4", flush=True)


if __name__ == "__main__":
    main()
