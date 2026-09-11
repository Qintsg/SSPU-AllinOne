import 'dart:io';

class McpNetworkService {
  const McpNetworkService();

  Future<List<String>> privateIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final values = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (isPrivateIpv4(address.address)) values.add(address.address);
      }
    }
    return values.toList()..sort();
  }

  bool isPrivateIpv4(String value) {
    final parts = value.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }
}
