#!/bin/bash

# -------------------------
# default values
# -------------------------
script_name=$(basename "${0}")
output_dir="converted"
input_files=()
preset=""
video_codec=""
audio_codec=""
gpu_enabled=false
mpeg4_quality=1
scaling=""
scaling_algorithm=""
fps=""
dry_run=false

# -------------------------
# usage string
# -------------------------
usage_string="Usage: ${script_name} "
usage_string+="-i <file> "
usage_string+="-p <value> "
usage_string+="[-o <value>] "
usage_string+="[-r <value>] "
usage_string+="[-s <value>] "
usage_string+="[-v <value>] "
usage_string+="[-a <value>] "
usage_string+="[--mpeg4-quality <value>] "
usage_string+="[--dnxhr-profile <value>] "
usage_string+="[--prores-profile <value>] "
usage_string+="[--fps <value>] "
usage_string+="[--gpu] "
usage_string+="[--dry-run] "
usage_string+="[-y] "
usage_string+="[-h]"

# -------------------------
# long usage function
# -------------------------
usage()
{
cat << EOF
${usage_string}

-i, --input   <file>     (Required) File(s) to encode

-p, --preset  <value>    (Required) Encoding preset
                           <dv> -> Settings for DaVinci Resolve import on Linux
                           <yt> -> YouTube recommended settings for upload

-o, --output <value>     (Optional) Output file name
                           -> If ignored, will use the input file name as prefix
                           -> DO NOT add the file extension

-r, --resolution <value> (Optional) Output video resolution
                           <2160> -> Ultra-HD (4k)
                           <1440> -> Quad-HD
                           <1080> -> Full HD
                           <720>  -> HD
                           <480>  -> SD

-s, --scaling <value>    (Optional) Scaling algorithm used when changing resolutions
                           <neighbor> -> Preserves hard edges and never blurs (default when upscaling)
                                       + Screen recordings
                                       + Sharp text
                           <bicubic>  -> Blends pixels to create a smooth transition
                                       + Fast general video resizing
                           <lanczos>  -> Preserves fine details and contrast (default when downscaling)
                                       + High quality video upscaling
                                       - Can create 'halos' around high-contrast edges

-v, --vcodec  <value>    (Optional) Video codec
                            <h264> -> Decent quality with modest files sizes (yt default)
                            <h265> -> High quality with even smaller file sizes
                           <dnxhd> -> Designed for post-production and fast editing performance (DNxHR)
                                    + High quality
                                    + Smooth playback
                                    + Fast encoding
                                    - Huge file size
                          <prores> -> Codec designed for editing
                                    + Fast editing speed
                                    + High visual fidelity
                                    - Large file size
                           <mpeg4> -> Old compression standard (dv default)
                                    + Very fast encoding
                                    + Medium file size
                                    - Inferior quality

                                    * MPEG-4 can develop artifacts or loss of image if
                                    it encounters bitrate data spikes in a frame.
                                    If you are having this problem, consider changing
                                    the --mpeg4-quality flag to lower values.
            
                      <mpeg2video> -> Prioritizes consistent file sizes over image quality
                                    + Small/Medium file size
                                    + Good performance
                                    - Visual artifacts (motion)
                            <copy> -> Keep the current video codec
                                    + Use it if you already have a codec compatible with DaVinci Resolve/YouTube
                                    - Ignores resolution options

-a, --acodec  <value>    (Optional) Audio codec
                           <aac>       -> YouTube recommended codec, compressed (yt default)
                           <pcm_s16le> -> 16-bit, cd-quality, smaller size, standard audio
                           <pcm_s24le> -> 24-bit, studio quality, 50% larger, professional audio (dv default)
                           <copy>      -> Keep the current audio codec
                                        + Use it if you already have a codec compatible with DaVinci Resolve/YouTube
                                        - Ignores filtering and mixing

--mpeg4-quality  <value> (Optional) MPEG4 video quality
                           <1>     -> best quality, largest size (default)
                           <2-4>   -> very good quality, large size
                           <5–10>  -> medium quality, medium size
                           <20–31> -> worst quality, small size

--dnxhr-profile  <value> (Optional) DNxHR profile (only for DNxHD codec)
                           <dnxhr_lb>  -> Low bandwidth (offline quality)
                           <dnxhr_sq>  -> Standard quality (suitable for delivery format) (default)
                           <dnxhr_hq>  -> High quality
                           <dnxhr_hqx> -> High quality (UHD/4K broadcast-quality delivery) 
                           <dnxhr_444> -> Finishing quality (cinema-quality delivery)

--prores-profile <value> (Optional) ProRes profile (only for ProRes codec)
                           <0> -> Lowest quality, offline editing
                           <1> -> Lightweight, visual quality often indistiguishable from Standard
                           <2> -> Standard quality (equivalent to DNxHR SQ) (default)
                           <3> -> High quality, visual fidelity
                           <4> -> Master quality, supports alpha channel

--fps  <value>           (Optional) Force output video FPS
                           <30> -> 30 FPS
                           <60> -> 60 FPS

--gpu                    (Optional) Enable NVIDIA GPU encoding (default: off)
                                -> h264 & h265 only

--dry-run                (Optional) Simulates the commands without executing them (default: off)

-y                       (Optional) Bypass confirmation warnings (default: off)
                                -> Overwrites output files without asking
                                -> Uses 'copy' codec without asking

-h, --help               (Optional) Show this help message


EXAMPLES:

-------------------------------------------------------
Use the defaults to create a video for DaVinci Resolve:
-------------------------------------------------------

./${script_name} -p dv -i input_file

-------------------------------------------------------
Use the defaults to create a video suited for YouTube:
-------------------------------------------------------

./${script_name} -p yt -i input_file

-------------------------------------------------------
Only convert the audio:
-------------------------------------------------------

./${script_name} -p dv -v copy -i input_file (for DaVinci Resolve)

 or

./${script_name} -p yt -v copy -i input_file (for YouTube)

-------------------------------------------------------
Enable GPU encoding and select output file:
-------------------------------------------------------

./${script_name} -p yt --gpu -i input_file -o gpu-encoded

-------------------------------------------------------
Specify the '2' quality for MPEG4:
-------------------------------------------------------

./${script_name} -p dv -v mpeg4 --mpeg4-quality 2 -i input_file

-------------------------------------------------------
Specify the 'dnxhr_hq' profile for DNxHR:
-------------------------------------------------------

./${script_name} -p dv -v dnxhd --dnxhr-profile dnxhr_hq

-------------------------------------------------------
Specify the '3' profile for ProRes:
-------------------------------------------------------

./${script_name} -p dv -v prores --prores-profile 3

-------------------------------------------------------
Force output overwrite when using 'copy' codec:
-------------------------------------------------------

./${script_name} -p yt -v copy -i input_file -y

-------------------------------------------------------
Force the output video FPS to 30:
-------------------------------------------------------

./${script_name} -p yt --fps 30 -i input_file 

-------------------------------------------------------
Set 4K resolution with the 'bicubic' scaling algorithm:
-------------------------------------------------------

./${script_name} -p yt -r 2160 -s bicubic -i input_file 

-------------------------------------------------------
Simulate ffmpeg's output:
-------------------------------------------------------

./${script_name} -p dv -i input_file --dry-run

-------------------------------------------------------
NOTE:
-------------------------------------------------------

DaVinci Resolve FREE on Linux does NOT work with the following codecs:

Video: H.264, H.265
Audio: AAC

DaVinci Resolve STUDIO on Linux does not work with the following codecs:

Audio: AAC
EOF
  exit 0
}

# -------------------------
# short usage function
# -------------------------
short_usage()
{
 
cat << EOF

${usage_string}

Run "${script_name} -h" or "${script_name} --help" for details.
EOF
}

# -------------------------
# confirm action function
# -------------------------
confirm_action()
{
  local message="${1}"    # first parameter  -> message to print
  local yes_action="${2}" # second parameter -> action when choosing yes
  local force_yes="${3}"  # third parameter  -> bypass confirmation flag 

  if ${force_yes:-false}
  then
    answer="y"
  else
    # append confirmation
    message+=" Do you want to continue anyway? [y/N] "
    echo -en "${message}"

    read -n 1 answer
    answer="${answer:-n}" # default is 'n'
    answer="${answer,,}"  # lower-case the answer
  fi

  case "${answer}" in
    y) eval "${yes_action}" ;;
    n) echo -e "Aborting.\n"; exit 1 ;;
    *) echo -e "Error: Invalid response. Aborting.\n"; exit 1 ;;
  esac
}

# -------------------------
# get correct encoder
# -------------------------
get_target_encoder()
{
  local codec="${1}" # first parameter  -> selected codec
  local gpu="${2}"   # second parameter -> gpu enabled/disabled

  # selects the proper codec depending on gpu enabled/disabled
  case "${codec}" in
    h264) ${gpu} && echo "h264_nvenc" || echo "libx264" ;;
    h265) ${gpu} && echo "hvec_nvenc" || echo "libx265" ;;
    *) echo "${codec}" ;;
  esac
}

# -------------------------
# check encoder
# -------------------------
check_encoder()
{
  local encoder="${1}" # selected encoder

  # if it's copy, allow
  if [[ "${encoder}" == "copy" ]]
  then
    return 0
  else
    # regex to get exact match of the encoder
    local regex="^[[:space:]]*[A-Z.]+[[:space:]]+${encoder}[[:space:]]"
    # check if the system has the encoder
    ffmpeg -hide_banner -encoders -v error | grep -E "${regex}" > /dev/null 2>&1
    return $?
  fi 
}

# check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
  echo "Error: ffmpeg is not installed."
  exit 1
fi

# argument parser
while [[ $# -gt 0 ]]
do
  case "${1}" in
    # get all input files
    -i|--input)
      shift
      # while still has arguments
      # and it's not another flag
      while [[ $# -gt 0 && ! "${1}" =~ ^- ]]
      do
        input_files+=("${1}")
        shift
      done
      ;;
           -p|--preset) preset="${2}";                                shift 2 ;;
           -v|--vcodec) video_codec="${2}";                           shift 2 ;;
           -o|--output) output_name="${2}";                           shift 2 ;;
           -a|--acodec) audio_codec="${2}";                           shift 2 ;;
       -r|--resolution) resolution="${2}";                            shift 2 ;;
          -s|--scaling) scaling_algorithm="${2}";                     shift 2 ;;
       --mpeg4-quality) mpeg4_quality="${2}";                         shift 2 ;;
       --dnxhr-profile) dnxhr_profile="${2}";                         shift 2 ;;
      --prores-profile) prores_profile="${2}";                        shift 2 ;;
                 --fps) fps="${2}";                                   shift 2 ;;
                 --gpu) gpu_enabled=true;                             shift   ;;
             --dry-run) dry_run=true;                                 shift   ;;
                    -y) bypass_confirmation=true;                     shift   ;;
             -h|--help) usage;                                                ;;
                    -*) echo "Unknown option: ${1}";      short_usage; exit 1 ;;
                     *) echo "Unexpected argument: ${1}"; short_usage; exit 1 ;;
  esac
done

# validate preset flag and input files
if [[ -z "${preset}" || -z "${input_files}" ]]
then
  echo "Error: Input file and preset are required."
  short_usage
  exit 1
fi

# create output folder
${dry_run} || mkdir -p "${output_dir}"

# -------------------------
# set dv variables
# -------------------------
if [[ "${preset}" == "dv" ]]
then
  video_codec="${video_codec:-mpeg4}"     # default video codec for dv
  audio_codec="${audio_codec:-pcm_s24le}" # default audio codec for dv
  extension="mov" # pcm needs .mov extension
  
  case "${audio_codec}" in
    pcm*) audio_flags="" ;;

    copy)
      message="Warning: DaVinci Resolve does not support AAC audio. "
      message+="If your source file uses an AAC codec, it might not work correctly."
      confirm_action "${message}" 'audio_flags=""' "${bypass_confirmation}" ;;

    *) echo "Error: Invalid audio codec for dv preset."; short_usage; exit 1 ;;
  esac

  case "${video_codec}" in
    dnxhd) 
      dnxhr_profile="${dnxhr_profile:-dnxhr_sq}" # default profile for dnxhr
      
      # dnxhr_lb  -> low bandwidth (offline quality)
      #           -  yuv422p      - 8-bit 4:2:2
      #
      # dnxhr_sq  -> standard quality (suitable for delivery format)
      #           -  yuv422p      - 8-bit 4:2:2
      #
      # dnxhr_hq  -> high quality
      #           -  yuv422p      - 8-bit 4:2:2
      #
      # dnxhr_hqx -> high quality (UHD/4K broadcast-quality delivery)
      #           -  yuv422p10le  - 10-bit 4:2:2
      #           -  yuv422p12le  - 12-bit 4:2:2
      #
      # dnxhr_444 -> finishing quality (cinema-quality delivery)
      #           -  yuv444p10le  - 10-bit 4:4:4
      #           -  yuv444p12le  - 12-bit 4:4:4
      
      case "${dnxhr_profile}" in
        dnxhr_lb|dnxhr_sq|dnxhr_hq) dnxhr_chroma="yuv422p" ;; # 8-bit
        dnxhr_hqx) dnxhr_chroma="yuv422p10le" ;;              # 10-bit
        dnxhr_444) dnxhr_chroma="yuv444p10le" ;;              # 10-bit
        *) echo "Error: Invalid DNxHR profile."; short_usage; exit 1 ;;
      esac

      video_flags="-profile:v ${dnxhr_profile} -pix_fmt ${dnxhr_chroma}"
      filename_end="-${dnxhr_profile}.${extension}"
      ;;

    prores)
      prores_profile="${prores_profile:-2}" # default profile for prores
      
      # 0 -> ProRes Proxy,  ~90 Mbps,  4:2:2, yuv422p10le
      # 1 -> ProRes 422 LT, ~204 Mbps, 4:2:2, yuv422p10le
      # 2 -> ProRes 422,    ~294 Mbps, 4:2:2, yuv422p10le
      # 3 -> ProRes 422 HQ, ~440 Mbps, 4:2:2, yuv422p10le
      # 4 -> ProRes 4444,   ~660 Mbps, 4:4:4, yuv444p10le

      case "${prores_profile}" in
        0|1|2|3) prores_chroma="yuv422p10le" ;; # 10-bit
        4)       prores_chroma="yuv444p10le" ;; # 10-bit
        *) echo "Error: Invalid ProRes profile."; short_usage; exit 1 ;;
      esac
      
      video_flags="-profile:v ${prores_profile} -pix_fmt ${prores_chroma}" 
      filename_end="-${prores_profile}.${extension}"
      ;;

    mpeg4)

      not_a_number="[[ ! ${mpeg4_quality} =~ ^[0-9]+$ ]]"
      out_of_range="(( 10#${mpeg4_quality} < 1 || 10#${mpeg4_quality} > 31 ))"

      # if it's not a number or it's out of range
      if eval "${not_a_number}" || eval "${out_of_range}"
      then
        echo "Error: Invalid MPEG4 quality."
        short_usage
        exit 1
      fi

      video_flags="-q:v ${mpeg4_quality}" # default quality: 1 (set on header)

      # -q:v N -> lower values = better quality, larger file
      #
      #      1 -> best quality, largest size
      #    2-4 -> very good quality, large size
      #   5–10 -> medium quality, medium size
      #  20–31 -> worst quality, small size

      filename_end=".${extension}"
      ;;

    mpeg2video)      
      video_flags="-pix_fmt yuv422p " # color resolution
      video_flags+="-b:v 100M "       # bitrate control
      video_flags+="-minrate 100M "   # minimum bitrate
      video_flags+="-maxrate 100M "   # maximum bitrate
      video_flags+="-bufsize 200M "   # data preload size
      video_flags+="-g 12 "           # one full frame + 11 partial frames
      video_flags+="-bf 2"            # bi-directional frames
      
      filename_end=".${extension}"
      ;;
    
    copy)
      message="Warning: DaVinci Resolve may be unable to decode H.264‑based videos. "
      message+="If your source file uses an H.264 codec, it might not work correctly."
      confirm_action "${message}" 'video_flags=""' "${bypass_confirmation}"
      
      filename_end=".${extension}"
      ;;

    *) echo "Error: Invalid video codec for dv preset."; short_usage; exit 1 ;;
  esac

  # map the video stream
  video_mapping="-map 0:v:0 -c:v ${video_codec} ${video_flags}"
fi

# -------------------------
# set yt variables
# -------------------------
if [[ "${preset}" == "yt" ]]
then
  video_codec="${video_codec:-h264}" # default video codec for yt
  audio_codec="${audio_codec:-aac}"  # default audio codec for yt
  extension="mp4"
  
  case "${audio_codec}" in
    aac)
      audio_flags="-b:a 384k " # audio bitrate recommended for YouTube
      audio_flags+="-ar 48000" # audio sample rate recommended for YouTube
      ;;

    copy)  			
      message="Warning: YouTube recommends using AAC as the audio codec."
      confirm_action "${message}" 'audio_flags=""' "${bypass_confirmation}" ;;

    *) echo "Error: Invalid audio codec for yt preset."; short_usage; exit 1 ;;
  esac
  
  video_codec=$(get_target_encoder "${video_codec}" "${gpu_enabled}")

  case "${video_codec}" in
    h264_nvenc)
      # gpu (nvidia) encoding for h264
      video_codec="h264_nvenc"
      video_flags="-preset slow "          # slower = better quality
      video_flags+="-rc:v vbr "            # variable bitrate
      video_flags+="-cq 18 "               # quality control (lower value = higher quality)
      video_flags+="-pix_fmt yuv420p "     # 8-bit, 4:2:0 chroma
      video_flags+="-movflags +faststart"  # fast playback start in streaming
      ;;

    libx264)
      # cpu encoding for h264
      video_codec="libx264"
      video_flags="-preset slow "              # slow = better compression, smaller file
      video_flags+="-crf 20 "                  # quality control (lower value = higher quality)
      video_flags+="-pix_fmt yuv420p "         # 8-bit, 4:2:0 chroma
      video_flags+="-x264-params opencl=true " # opencl support in x264 for gpu-assisted filters
      video_flags+="-movflags +faststart"      # fast playback start in streaming
      ;;

    hvec_nvenc)
      # gpu (nvidia encoding) for h265
      video_codec="hevc_nvenc"
      video_flags="-preset slow "          # slower = better quality
      video_flags+="-rc:v vbr "            # variable bitrate
      video_flags+="-cq 21 "               # quality control (lower value = higher quality)
      video_flags+="-pix_fmt yuv420p "     # 8-bit, 4:2:0 chroma
      video_flags+="-movflags +faststart " # fast playback start in streaming
      video_flags+="-tag:v hvc1"           # fixes playback compatibility on apple software
      ;;

    libx265)
      # cpu encoding for h265
      video_codec="libx265"
      video_flags="-preset slow "          # slow = better compression, smaller file
      video_flags+="-crf 24 "              # quality control (lower value = higher quality)
      video_flags+="-pix_fmt yuv420p "     # 8-bit, 4:2:0 chroma
      video_flags+="-movflags +faststart " # fast playback start in streaming
      video_flags+="-tag:v hvc1"           # fixes playback compatibility on apple software
      ;;

    copy)
      message="Warning: Files that are not encoded with H.264 "
      message+="will not use YouTube’s recommended settings."
      confirm_action "${message}" 'video_flags=""' "${bypass_confirmation}"
      ;;

    *) echo "Error: Invalid video codec for yt preset."; short_usage; exit 1 ;;
  esac

  # filename ending
  filename_end=".${extension}"
  # map the video stream
  video_mapping="-map 0:v:0 -c:v ${video_codec} ${video_flags}"
fi

# -------------------------
# resolution settings
# -------------------------
case "${resolution}" in
  2160|1440|1080|720|480)

    # remove filtering if using 'copy' video codec
    if [[ "${video_codec}" == "copy" ]]
    then
      video_filter_flags=""
    else
      video_filter_flags="-vf scale=-2:${resolution}"
    fi

    ;;
  
  "") video_filter_flags="" ;;
   *) echo "Error: Invalid resolution."; short_usage; exit 1 ;;
esac

# -------------------------
# fps settings
# -------------------------
case "${fps}" in
  30) fps_flag="-r 30" ;;
  60) fps_flag="-r 60" ;;
  "") fps_flag=""      ;;
   *) echo "Error: Invalid FPS value."; short_usage; exit 1 ;;
esac

# scaling validation
if [[ ! "${scaling_algorithm}" =~ ^($|neighbor|bicubic|lanczos)$ ]]
then
  echo "Error: Invalid scaling value."
  short_usage
  exit 1
fi

# check video encoder
if ! check_encoder ${video_codec}
then
  echo "Error: you do not have the "${video_codec}" video encoder."
  exit 1
fi

# check audio encoder
if ! check_encoder ${audio_codec}
then
  echo "Error: you do not have the "${audio_codec}" audio encoder."
  exit 1
fi

# -------------------------
# loop through files
# -------------------------
for file in "${input_files[@]}"
do
  # validate file
  if [ ! -e "${file}" ]
  then
    echo "Warning: File ${file} does not exist. Skipping."
    continue
  fi

  # get file type
  mime_type=$(file --mime-type -b "${file}")

  # validate file type
  if [[ "${mime_type}" != video/* ]]
  then
    echo "Warning: File ${file} is not a video. Skipping."
    continue
  fi

  # if resolution is set and it's not the 'copy' video codec
  if [[ ! -z ${resolution} && "${video_codec}" != "copy" ]]
  then
    # get current resolution
    current_resolution=$(
      ffprobe \
        -v error \
        -select_streams v:0 \
        -show_entries stream=height \
        -of csv=p=0 \
        "${file}"
    )

    # use lanczos by default when downscaling
    if [ ${current_resolution} -gt ${resolution} ]
    then
      scaling=":flags=${scaling_algorithm:-lanczos}"
    # use nearest neighbor by default when upscaling
    elif [ ${current_resolution} -lt ${resolution} ]
    then
      message="The current video resolution is lower than the target resolution. "
      message+="The video will be upscaled."
      confirm_action "${message}" scaling=":flags=${scaling_algorithm:-neighbor}" "${bypass_confirmation}"
    else
      # remove scaling if output resolution is the same as input
      video_filter_flags=""
    fi

    video_filter_flags+="${scaling}"
  fi

  # get the number of audio streams
  audio_streams_count=$(
    ffprobe \
      -v error \
      -select_streams a \
      -show_entries stream=index \
      -of csv=p=0 \
      "${file}" \
    | wc -l
  )

  # audio settings for dv preset
  if [[ "${preset}" == "dv" ]]
  then 
    audio_mapping=""
    
    if [[ "${audio_streams_count}" -gt 0 ]]
    then
      # map each track to a new track with the output codec
      for ((i = 0; i < ${audio_streams_count}; i++))
      do
        audio_mapping+="-map 0:a:${i} "  # map each audio track
        audio_mapping+="-c:a:${i} "      # select audio track
        audio_mapping+="${audio_codec} " # output audio codec
      done
    else
      audio_mapping="-an" # ignores audio if there is none
    fi
  fi

  # audio settings for yt preset
  if [[ "${preset}" == "yt" ]]
  then
    if [[ "${audio_streams_count}" -gt 0 ]]
    then
      if [[ "${audio_codec}" != "copy" ]]
      then
        audio_labels=""
        # prepare audio labels for mixing
        for (( i = 0; i < ${audio_streams_count}; i++ ))
        do
          audio_labels+="[0:a:${i}]"
        done
  
        filter_complex="${audio_labels}"                      # audio labels
        filter_complex+="amix=inputs=${audio_streams_count}:" # mix N inputs
        filter_complex+="duration=longest:"                   # pick the longest duration for output
        filter_complex+="dropout_transition=3,"               # smooths transitions between streams
        filter_complex+="pan=stereo|c0=FL|c1=FR[aout]"        # stereo output configuration
      
        audio_mapping="-c:a ${audio_codec} ${audio_flags} " # audio options
        audio_mapping+="-filter_complex ${filter_complex} " # mix each audio track into one
        audio_mapping+="-map [aout] "                       # map the configuration set by filter_complex
        audio_mapping+="-ac 2 "                             # force output to stereo
      else
        audio_mapping="-c:a ${audio_codec} ${audio_flags}" # audio options
      fi
    else
      audio_mapping="-an" # ignores audio if there is none
    fi
  fi

  if [[ -z "${output_name}" ]]
  then
    filename=$(basename "${file}") # make sure it has only the file name
    name="${filename%.*}"          # remove file extension
    name="${name,,}"               # lower case
    name="${name// /-}"            # replace spaces with dashes
    output="${name}-${resolution}-${fps}-${video_codec}${filename_end}" # final output name
    output=$(printf '%s' "${output}" | sed -E 's/-+/-/g') # removes two or more dashes in a row
  else
    output="${output_name}.${extension}"
  fi

  # overwrite output files without asking
  ${bypass_confirmation:-false} && force_flag="-y" || force_flag=""

  ffmpeg_cmd=(
    ffmpeg
    ${force_flag}             # force overwrites
    -i "${file}"              # file to be converted
    ${video_mapping}          # video mapping options
    ${video_filter_flags}     # resolution and scaling algorithm options
    ${fps_flag}               # fps options
    ${audio_mapping}          # audio mapping options
    -hide_banner              # hide unnecessary info
    "${output_dir}/${output}" # output dir/file
  )

  # run command
  echo -e "\nRunning \033[1m${ffmpeg_cmd[@]}\033[0m\n"
  ${dry_run} || "${ffmpeg_cmd[@]}"

  # check if ffmpeg failed
  if [ $? -ne 0 ]
  then
    echo -e "Error: Could not convert \033[1m${file}\033[0m to \033[1m${video_codec}\033[0m codec."
  else
    echo "Process finished."
  fi
done

# remove temporary file
rm -f "x264_lookahead.clbin"
exit 0
