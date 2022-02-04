import 'dart:async';

import 'package:at_base2e15/at_base2e15.dart';
import 'package:at_client/at_client.dart';
import 'package:at_client/src/decryption_service/decryption_manager.dart';
import 'package:at_client/src/manager/at_client_manager.dart';
import 'package:at_client/src/response/default_response_parser.dart';
import 'package:at_client/src/response/json_utils.dart';
import 'package:at_client/src/transformer/at_transformer.dart';
import 'package:at_client/src/util/at_client_util.dart';
import 'package:at_commons/at_commons.dart';

/// Class responsible for transforming the Get response
/// Transform's the Get Response to [AtValue]
///
/// Decodes the binary data and decrypts the encrypted data
class GetResponseTransformer
    implements Transformer<Tuple<AtKey, String>, AtValue> {
  @override
  FutureOr<AtValue> transform(Tuple<AtKey, String> tuple) async {
    var atValue = AtValue();
    var decodedResponse =
        JsonUtils.decodeJson(DefaultResponseParser().parse(tuple.two).response);

    atValue.value = decodedResponse['data'];
    // parse metadata
    if (decodedResponse['metaData'] != null) {
      atValue.metadata = AtClientUtil.prepareMetadata(
          decodedResponse['metaData'],
          decodedResponse['key'].startsWith('public:'));
    }

    // If data is binary, decode the data
    if (atValue.metadata != null &&
        atValue.metadata!.isBinary != null &&
        atValue.metadata!.isBinary!) {
      atValue.value = Base2e15.decode(atValue.value);
    }

    // If data is encrypted, decrypt the data
    if (atValue.metadata != null &&
        atValue.metadata!.isEncrypted != null &&
        atValue.metadata!.isEncrypted!) {
      var decryptionService = AtKeyDecryptionManager.get(tuple.one,
          AtClientManager.getInstance().atClient.getCurrentAtSign()!);
      atValue.value =
          await decryptionService.decrypt(tuple.one, atValue.value) as String;
    }
    return atValue;
  }
}
