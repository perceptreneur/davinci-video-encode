# DaVinci Resolve & YouTube Video Encoder

A bash script wrapper for FFmpeg designed to save time when transcoding videos. It provides presets for importing media into DaVinci Resolve on Linux, as well as high-quality presets to prepare the video for YouTube uploading.

It keeps the audio tracks separated for convenient editing in DaVinci Resolve and merges all tracks when encoding for YouTube.

This script is a personal solution for this problem. It's made to adapt to my workflow and help me save time. The decisions on the presets follow that mindset.

### Video Encoding Workflow

Raw video -> Reencoded for DaVinci -> Exported from DaVinci -> Reencoded for Youtube

## Important Note for Linux Users
* **DaVinci Resolve FREE** does NOT support encoding/decoding H.264/H.265 video or AAC audio. 
* **DaVinci Resolve STUDIO** does NOT support encoding/decoding AAC audio.
* This script provides the `dv` preset to easily convert incompatible media into formats that Resolve on Linux can read.

## Caveats
* You must have `ffmpeg` installed on your system to use this script, but it will check if you have it anyway.
* To use the `--gpu` flag, you need an NVIDIA GPU with the appropriate drivers installed. No AMD support.

## Usage

```bash
./davinci-video-encode.sh -p <preset> -i <file> [options]
```

### Required Arguments
* `-i, --input <file>` : File(s) to encode. You can pass multiple files.
* `-p, --preset <value>` : Encoding preset.
  * `dv` -> Settings for DaVinci Resolve import on Linux.
  * `yt` -> YouTube recommended settings for upload.

### Optional Arguments
* `-o, --output <value>` : Output file name (DO NOT add the file extension). If ignored, uses the input file name as a prefix.
* `-r, --resolution <value>` : Output video resolution (`2160`, `1440`, `1080`, `720`, `480`).
* `-s, --scaling <value>` : Scaling algorithm when changing resolutions (`neighbor`, `bicubic`, `lanczos`).
* `-v, --vcodec <value>` : Video codec override (`h264`, `h265`, `dnxhd`, `prores`, `mpeg4`, `mpeg2video`, `copy`).
* `-a, --acodec <value>` : Audio codec override (`aac`, `pcm_s16le`, `pcm_s24le`, `copy`).
* `--fps <value>` : Force output video FPS (`30`, `60`).
* `--gpu` : Enable NVIDIA GPU encoding (for H.264 and H.265 only).
* `--dry-run` : Simulates the FFmpeg commands without executing them.
* `-y` : Bypass confirmation warnings (overwrites output files automatically).
* `-h, --help` : Show the full help message.

### Advanced Quality Profiles
* `--mpeg4-quality <1-31>` : Set MPEG4 visual quality (1 is best, default is 1).
* `--dnxhr-profile <profile>` : For DNxHD codec (`dnxhr_lb`, `dnxhr_sq` [default], `dnxhr_hq`, `dnxhr_hqx`, `dnxhr_444`).
* `--prores-profile <0-4>` : For ProRes codec (Higher is better, default is `2`).

---

## Examples

**Use the defaults to create a video for DaVinci Resolve:**
```bash
./davinci-video-encode.sh -p dv -i input_file
```

**Use the defaults to create a video suited for YouTube:**
```bash
./davinci-video-encode.sh -p yt -i input_file
```

**Only convert the audio:**
```bash
./davinci-video-encode.sh -p dv -v copy -i input_file (for DaVinci Resolve)
```
 or
```bash
./davinci-video-encode.sh -p yt -v copy -i input_file (for YouTube)
```

**Enable GPU encoding and select output file:**
```bash
./davinci-video-encode.sh -p yt --gpu -i input_file -o gpu-encoded
```

**Specify the '2' quality for MPEG4:**
```bash
./davinci-video-encode.sh -p dv -v mpeg4 --mpeg4-quality 2 -i input_file
```

**Specify the 'dnxhr_hq' profile for DNxHR:**
```bash
./davinci-video-encode.sh -p dv -v dnxhd --dnxhr-profile dnxhr_hq
```

**Specify the '3' profile for ProRes:**
```bash
./davinci-video-encode.sh -p dv -v prores --prores-profile 3
```

**Force output overwrite when using 'copy' codec:**
```bash
./davinci-video-encode.sh -p yt -v copy -i input_file -y
```

**Force the output video FPS to 30:**
```bash
./davinci-video-encode.sh -p yt --fps 30 -i input_file 
```

**Set 4K resolution with the 'bicubic' scaling algorithm:**
```bash
./davinci-video-encode.sh -p yt -r 2160 -s bicubic -i input_file
```

**Simulate ffmpeg's output:**
```bash
./davinci-video-encode.sh -p dv -i input_file --dry-run
```

