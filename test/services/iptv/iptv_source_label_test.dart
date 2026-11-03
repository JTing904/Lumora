import 'package:flutter_test/flutter_test.dart';
import 'package:zplay/services/iptv/iptv_source_label.dart';

String _label({String username = '', String name = '', String url = ''}) =>
    IptvSourceLabel.labelFor(
      username: username,
      name: name,
      url: url,
      fallback: 'Server 3',
    );

void main() {
  test('a portal is named by its host, never its login', () {
    final label = _label(
      username: 'john_doe_77',
      name: 'john_doe_77',
      url: 'http://www.line.example-tv.com:8080',
    );
    expect(label, 'line.example-tv.com');
    expect(label.contains('john'), isFalse);
  });

  test('a portal without a host falls back to its number', () {
    expect(_label(username: 'john', name: 'john', url: ''), 'Server 3');
  });

  test('a host that spells the login is not used', () {
    expect(
      _label(username: 'john', name: 'john', url: 'http://john.example.com'),
      'Server 3',
    );
  });

  test('a playlist keeps the label the app gave it', () {
    expect(
      _label(name: 'Free Sports (iptv-org)', url: 'https://cdn.example/a.m3u8'),
      'Free Sports (iptv-org)',
    );
  });

  test('a playlist name that is a URL is shortened to its host', () {
    expect(
      _label(name: 'https://cdn.example/a.m3u8?token=x', url: ''),
      'Server 3',
    );
    expect(
      _label(
        name: 'https://cdn.example/a.m3u8?token=x',
        url: 'https://cdn.example/a.m3u8?token=x',
      ),
      'cdn.example',
    );
  });
}
