import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/engine_failure.dart';

final class StockfishBinary {
  const StockfishBinary({
    required this.path,
    required this.abi,
    required this.sourceVersion,
    required this.sha256,
    required this.distributionVerified,
  });

  final String path;
  final String abi;
  final String sourceVersion;
  final String sha256;
  final bool distributionVerified;
}

abstract interface class StockfishBinaryResolver {
  Future<StockfishBinary> resolve();
}

final class PlatformStockfishBinaryResolver implements StockfishBinaryResolver {
  const PlatformStockfishBinaryResolver();

  static const MethodChannel _channel = MethodChannel(
    'in.sanskar.chessmaster/engine',
  );
  static const Set<String> _supportedAndroidAbis = <String>{
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
  };

  @override
  Future<StockfishBinary> resolve() async {
    const String developmentPath = String.fromEnvironment(
      'CHESS_MASTER_STOCKFISH_PATH',
    );
    if (developmentPath.isNotEmpty) {
      final File binary = File(developmentPath);
      if (!await binary.exists()) {
        throw const EngineFailure(
          code: EngineFailureCode.binaryUnavailable,
          message: 'The configured development engine binary does not exist.',
        );
      }
      return const StockfishBinary(
        path: developmentPath,
        abi: 'development-host',
        sourceVersion: 'developer-supplied',
        sha256: 'not-for-distribution',
        distributionVerified: false,
      );
    }

    if (!Platform.isAndroid) {
      throw const EngineFailure(
        code: EngineFailureCode.binaryUnavailable,
        message: 'No Stockfish development path is configured.',
      );
    }

    final Map<Object?, Object?>? environment = await _channel
        .invokeMapMethod<Object?, Object?>('engineEnvironment');
    final List<String> abis = environment?['supportedAbis'] is List<Object?>
        ? (environment!['supportedAbis']! as List<Object?>)
              .whereType<String>()
              .toList(growable: false)
        : const <String>[];
    if (!abis.any(_supportedAndroidAbis.contains)) {
      throw EngineFailure(
        code: EngineFailureCode.unsupportedArchitecture,
        message: 'This Android device architecture is not supported.',
        technicalDetails: abis.join(','),
      );
    }

    final Object? path = environment?['verifiedBinaryPath'];
    final Object? abi = environment?['verifiedAbi'];
    final Object? version = environment?['sourceVersion'];
    final Object? checksum = environment?['sha256'];
    final Object? verified = environment?['distributionVerified'];
    if (path is! String ||
        abi is! String ||
        version is! String ||
        checksum is! String ||
        verified != true) {
      throw const EngineFailure(
        code: EngineFailureCode.binaryUnavailable,
        message:
            'No verified Stockfish binary is bundled with this application.',
      );
    }
    if (!_supportedAndroidAbis.contains(abi)) {
      throw EngineFailure(
        code: EngineFailureCode.unsupportedArchitecture,
        message: 'The bundled Stockfish ABI is not supported.',
        technicalDetails: abi,
      );
    }
    return StockfishBinary(
      path: path,
      abi: abi,
      sourceVersion: version,
      sha256: checksum,
      distributionVerified: true,
    );
  }
}
