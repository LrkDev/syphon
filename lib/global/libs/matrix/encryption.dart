// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/values.dart';

class Algorithms {
  static const signedcurve25519 = 'signed_curve25519';
  static const curve25591 = 'curve25519';
  static const ed25519 = 'ed25519';
  static const olmv1 = 'm.olm.v1.curve25519-aes-sha2';
  static const megolmv1 = 'm.megolm.v1.aes-sha2';
}

class Keys {
  static fingerprint({String? deviceId}) => '${Algorithms.ed25519}:$deviceId';
  static identity({String? deviceId}) => '${Algorithms.curve25591}:$deviceId';
}

abstract class Encryption {
  /// Fetch Encryption Keys
  /// 
  /// https://matrix.org/docs/spec/client_server/latest#id460
  /// 
  /// Returns the current devices and identity keys for the given users.
  static Future<dynamic> fetchKeys({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    int timeout = 10 * 1000, // 10 seconds
    String? lastSince,
    Map<String, dynamic> users = const {},
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/keys/query';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'timeout': timeout,
      'device_keys': users,
      'token': lastSince,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Fetch Room Keys
  /// 
  /// https://matrix.org/docs/spec/client_server/latest#id460
  /// 
  /// Returns the current devices and identity keys for the given users.
  static Future<dynamic> fetchRoomKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String? accessToken,
    int timeout = 10 * 1000, // 10 seconds
    String? lastSince,
    Map<String, dynamic> users = const {},
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/unstable/room_keys/version';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /// 
  /// Fetch Key Changes
  /// 
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-keys-changes
  /// 
  /// Gets a list of users who have updated their device identity keys since a previous sync token.
  /// 
  /// The server should include in the results any users who:
  ///   - currently share a room with the calling user (ie, both users have membership state join); and
  ///   - added new device identity keys or removed an existing device with identity keys, between from and to.
  /// 
  static Future<dynamic> fetchKeyChanges({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String? accessToken,
    String? from,
    String? to,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/keys/changes';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /// Claim Keys
  /// 
  /// https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-keys-claim
  /// 
  /// Claims one-time keys for use in pre-key messages.
  /// 
  static Future<Map<String, dynamic>> claimKeys({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    Map? oneTimeKeys,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/keys/claim';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'timeout': 10000,
      'one_time_keys': oneTimeKeys,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> uploadKeys({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    Map? data,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/keys/upload';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );

    return await json.decode(response.body);
  }

  ///
  /// Request Keys
  ///
  /// https://matrix.org/docs/spec/client_server/latest#m-room-key-request
  ///
  /// Returns the current devices and identity keys for the given users.
  ///
  static Future<dynamic> requestKeys({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    String? requestId,
    String? roomId,
    String? userId,
    String? deviceId,
    String? senderKey,
    String? sessionId,
    String? requestingUserId,
    String? requestingDeviceId,
  }) async {
    final Map content = {
      'content': {
        'action': 'request',
        // 'LWKAFEZEIV',
        'requesting_device_id': requestingDeviceId,
        'request_id': requestId,
        'body': {
          'room_id': roomId,
          'algorithm': Algorithms.megolmv1,
          'sender_key': senderKey,
          'session_id': sessionId
        }
      },
      'type': EventTypes.roomKeyRequest,
      'sender': requestingUserId
    };

    // format payload for toDevice events
    final payload = {
      userId: {
        deviceId: content,
      },
    };

    printJson(payload);

    return MatrixApi.sendEventToDevice(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      eventType: EventTypes.roomKeyRequest,
      trxId: DateTime.now().millisecond.toString(),
      content: payload,
    );
  }
}
