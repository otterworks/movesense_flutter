package works.otter.movesense_flutter;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.Context;
import android.util.Log;

import com.movesense.mds.Mds;
import com.movesense.mds.MdsConnectionListener;
import com.movesense.mds.MdsException;
import com.movesense.mds.MdsResponseListener;
// without these below, mds.connect fails
import io.reactivex.disposables.Disposable;
import com.polidea.rxandroidble2.RxBleDevice; 

public class MovesenseFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "MovesenseFlutterPlugin";
  private Context context = null;
  private MethodChannel methodChannel;
  private static Mds mds;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    onAttachedToEngine(flutterPluginBinding.getApplicationContext(), flutterPluginBinding.getBinaryMessenger());
  }

  public static void registerWith(Registrar registrar) {
    final MovesenseFlutterPlugin instance = new MovesenseFlutterPlugin();
    instance.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  private void onAttachedToEngine(Context context, BinaryMessenger messenger) {
    this.context = context;
    methodChannel = new MethodChannel(messenger, "otter.works/movesense_whiteboard");
    methodChannel.setMethodCallHandler(this);
    mds = Mds.builder().build(this.context);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) { // TODO: revisit final modifier
    final String path = call.argument("path");
// TODO: seems like get/put/post/delete below are boilerplate and I should be able to implement them with some sort of function factory, but let's stick with the simple boilerplate for now
    switch (call.method) {
      case "connect": {
        final String mac = call.argument("mac");
        mds.connect(mac,
          new MdsConnectionListener() {
            @Override
            public void onConnect(String s) {
              Log.d(TAG, "mds.connect onConnect: " + s);
            }
            @Override
            public void onConnectionComplete(String macAddress, String serialNumber) {
              Log.d(TAG, "mds.connect onConnectionComplete: MAC: " + macAddress + ", serial #: " + serialNumber);
              Long serial = Long.parseLong(serialNumber);
              Log.d(TAG, String.format("returning serial # %d as type Long", serial));
              result.success(serial);
            }
            @Override
            public void onError(MdsException e) {
              Log.e(TAG, "mds.connect onError" + e);
              result.error("MDS Exception", null, e);
            }
            @Override
            public void onDisconnect(String macAddress) {
              Log.d(TAG, "mds.connect onDisconnect: " + macAddress);
              // do not write the result, it has already been sent
            }
          }
        );
        break;
      } case "disconnect": {
        final String mac = call.argument("mac");
        mds.disconnect(mac);
        result.success(200);
        break;
      } case "get": {
        mds.get(path, null,
          new MdsResponseListener() {
            @Override
            public void onSuccess(String data) {
              Log.d(TAG, String.format("GET received whiteboard response of type %s:", data.getClass().getName()));
              Log.d(TAG, data);
              result.success(data);
            }
            @Override
            public void onError(MdsException e) {
              Log.e(TAG, "GET returned error:" + e);
              result.error("MDS Exception", null, e);
            }
          } // MdsResponseListener
        ); // mds.get
        break;
      } case "put": {
        String contract = call.argument("contract");
        Log.d(TAG, String.format("PUT %s : %s", path, contract));
        mds.put(path, contract,
          new MdsResponseListener() {
            @Override
            public void onSuccess(String data) {
              Log.d(TAG, String.format("PUT received whiteboard response of type %s:", data.getClass().getName()));
              Log.d(TAG, data);
              result.success(data);
            }
            @Override
            public void onError(MdsException e) {
              Log.e(TAG, "PUT returned error:" + e);
              result.error("MDS Exception", null, e);
            }
          } // MdsResponseListener
        ); // mds.put
        break;
      } case "post": {
        mds.post(path, null,
          new MdsResponseListener() {
            @Override
            public void onSuccess(String data) {
              Log.d(TAG, String.format("POST received whiteboard response of type %s:", data.getClass().getName()));
              Log.d(TAG, data);
              result.success(data);
            }
            @Override
            public void onError(MdsException e) {
              Log.e(TAG, "POST returned error:" + e);
              // TODO: allow CONTINUE somehow...
              result.error("MDS Exception", null, e);
            }
          } // MdsResponseListener
        ); // mds.post
        break;
      } case "delete": {
        mds.delete(path, null,
          new MdsResponseListener() {
            @Override
            public void onSuccess(String data) {
              Log.d(TAG, String.format("DELETE received whiteboard response of type %s:", data.getClass().getName()));
              Log.d(TAG, data);
              result.success(data);
            }
            @Override
            public void onError(MdsException e) {
              Log.e(TAG, "DELETE returned error:" + e);
              result.error("MDS Exception", null, e);
            }
          } // MdsResponseListener
        ); // mds.delete
        break;
      } default: {
        Log.wtf(TAG, String.format("Yo! %s is not a valid MDS Whiteboard action."));
        result.notImplemented();
      }
    } // switch
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
}
