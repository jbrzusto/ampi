# ampi - AudioMoth on Raspberry Pi

This repo supports creation of a fleet of systems for the
[Motus](https://motus.org) acoustic monitoring project.

**TLDR:** A [Raspberry Pi](https://raspberrypi.org) records from a USB
[AudioMoth](https://www.openacousticdevices.info/audiomoth) and
uploads files to an [Amazon S3 bucket](https://aws.amazon.com/s3/)
where a machine-learning pipeline extracts bird night-flight calls.

## Software components

- **[ffmpeg](https://ffmpeg.org)**: recording, resampling and compressing audio
- **[AWS client](https://awscli.amazonaws.com/)**: uploading files to an Amazon S3 bucket
- **[shiftwrap](https://github.com/jbrzusto/shiftwrap)**: scheduling recordings
- **[ampi](https://github.com/jbrzusto/ampi)**: in-field configuration via bluetooth, live listening, superglue
- **[fleetsie](https://github.com/jbrzusto/fleetsie)**: provisioning a fleet of devices
- **[zabbix](https://zabbix.com)**: fleet monitoring
