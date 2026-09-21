import MediaField from './MediaField';

export { resolveMediaUrl, resolveAudioUrl } from './MediaField';

/** Back-compat: existing lessons/phrases import AudioField. */
export default function AudioField(props) {
  return (
    <MediaField
      {...props}
      label={props.label || 'Audio'}
      accept="audio/*"
      endpoint="/admin/audio"
      audioOnly
    />
  );
}
