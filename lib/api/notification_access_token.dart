import 'dart:developer';

import 'package:googleapis_auth/auth_io.dart';

class NotificationAccessToken {
  static String? _token;

  //to generate token only once for an app run
  static Future<String?> get getToken async => _token ?? await _getAccessToken();

  // to get admin bearer token
  static Future<String?> _getAccessToken() async {
    try {
      const fMessagingScope =
          'https://www.googleapis.com/auth/firebase.messaging';

      final client = await clientViaServiceAccount(
        // To get Admin Json File: Go to Firebase > Project Settings > Service Accounts
        // > Click on 'Generate new private key' Btn & Json file will be downloaded

        // Paste Your Generated Json File Content
        ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": "tocha-49ef1",
          "private_key_id": "61797a8b0277b5ee1d05dc653fa971252cce4ac0",
          "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCOR9DZBD1gD+Jl\n3nGPwJQ1u+nqyMafwmze9H4o/GzI6Vfns3Ux9ZroVe8vXI9zOspdje/GmPLgmIlU\nczpojK5nhC8Trspbo40KQ4lA9/pkZms77cNMYtvH2RtsT6hHJhpPOIRUEf9Sgutx\nYQCDXAJcfrMKoqbp4qB+LlXfjFwZneeG2pQDmCigGroV6GVgWIKFnr+HLWHyv99f\n5Bf363e9oNZNd3IWuagt6RAo9GCQ1LmOTl57IE7sKe7SeCZj/5xMMLY4+OY6+y23\nANRQ9XDswm8AVkTRbrFqN2i8NDOSN4GTozhqErVuQMsAc3ICF2YfuW6O7+/s2OdL\nNxPbjhL/AgMBAAECggEAP0EOSGzqHFrze/Z45j/npDv2srqwEzaM0FJCBFa0xl13\nBztxTtSyGbiaraOo4sGwVgdUIia9U7x80V6pCPICV2McytNag4MioP2Fd6zHVPtz\nkSETQlJxA1gyKOUBGyCFcdLegcG+kSBDLBTD9aJiKlzpnEDTlAd88pwG8WulRn2T\nTqRh0BnZAoEU1wjXE76FCYkesHEiUVxD3N17w889hHTk5+XUq0mk0lhym4AOF0Xq\nJEWFAPE6Q4m/vcdf0pOtOZk6VGn5OOf5TnAxaYlJyeCvelukmWH484DBdCLZAgPV\noTbEknbie2wYeXMw68IjdCfA3I6HRGmirqhHbJEdAQKBgQC/VD6lP0kH4kHr4FqQ\nt6XLcNL6IqlbtPB0p2nbUsm0aSSFMafXLlkQ0ksoRN1vzsuZ7KZBKYsD+NkM46Ls\nO8KzOBjf0H7JM9QQ5eZmePlcP7sJ9KocjJAiqRYE3RVKjP1FCkQLoqXQtSPI5TCS\n4UVH0DCd0OLW3dUN76z28wUqGQKBgQC+X2MiLjSeUD6puiSxHyjeF5+yVH2shzTf\nCtjF14EQ5huDmxWBK98dOi6pcBYDQBpDG/dSQuhrPhIDd0aOsz4tbOJhvuWt8Vof\n2nBTeCd9zbFGuTGUMSFQSbDhgkx74tAHoiVYR0EhAzZrWo+tywnvuQNb4Xuz0E63\ni4Wzkdx41wKBgQCkMvSgdLOEZJUWjbCryjArbGRj7yNRZPOH6bVbWK1qe2GwPXFB\nprEhUpjVsmQn9F2feA0mlzSK8CG2ghXsj00E6fvO+OwWWLiC2ArnnqLCnJ80aBkl\n7ywz0tDm06XWGTGy8qB7K9cKSqqvWqJZK6N9ghp3FjHXHQIft7XFKcMg4QKBgFW9\nxntljiNjhuWQxefUXeaxgyahcTzcZI60Zu+sYSAIU4oRtjzIUqPqSYvcxL1QCMQC\n+4BcTCvI9/oBpZCt4Co7aTaW8QFHu8yu6HpfmoHJu7dbv528BwIPPpBCzEnb3NAj\nUmiRJx9EQCVX03B2CxKiJIYkZz+UaW+3ck9vOXpfAoGBAJklop++gGNIKIEETmBn\nGT2qNRIzPSA2EVYfd8xSTXOea/DNKp6Y8EH6w01RGMKFgLwP3FUktjJSPtQB+VxM\nl0WaxI7w6qPOVajOkSk1VHnWRgxhhGzMkFk6wUW9rUVvI1TkJZfb5c2byhrut93N\ngzxFgbN4eXCAQRN7w1l5syhU\n-----END PRIVATE KEY-----\n",
          "client_email": "firebase-adminsdk-rx7ch@tocha-49ef1.iam.gserviceaccount.com",
          "client_id": "113492370832306587267",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-rx7ch%40tocha-49ef1.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com"

        }),
        [fMessagingScope],
      );

      _token = client.credentials.accessToken.data;

      return _token;
    } catch (e) {
      log('$e');
      return null;
    }
  }
}