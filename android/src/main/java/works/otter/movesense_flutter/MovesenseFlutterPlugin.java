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
  private Context context = null;
  private MethodChannel methodChannel;
  private static Mds mds;
  private static long serial;
  private static String mac;

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

  private void getConnectedDevices() {
    mds.get("suunto://MDS/ConnectedDevices", null,
      new MdsResponseListener() {
        @Override
        public void onSuccess(String data) {
          Log.d("MovesenseFlutterPlugin", data);
        }
        @Override
        public void onError(MdsException e) {
          Log.e("MovesenseFlutterPlugin", "Error getting connected devices", e);
        }
      } // MdsResponseListener
    ); // mds.get
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) { // TODO: revisit final modifier
    final String path = call.argument("path");
    if (call.method.equals("connect")) {
      serial = call.argument("serial");
      Log.d("MovesenseFlutterPlugin",String.format("set Movesense serial # %d", serial));
      mac = call.argument("mac");
      Log.d("MovesenseFlutterPlugin",String.format("set Movesense MAC address %s", mac));
      mds.connect(mac,
        new MdsConnectionListener() {
          @Override
          public void onConnect(String s) {
            Log.d("MovesenseFlutterPlugin", "mds.connect onConnect: " + s);
          }
          @Override
          public void onConnectionComplete(String macAddress, String serialNumber) {
            Log.d("MovesenseFlutterPlugin", "mds.connect onConnectionComplete: " + macAddress + " " + serialNumber);
            result.success(200);
          }
          @Override
          public void onError(MdsException e) {
            Log.e("MovesenseFlutterPlugin", "mds.connect onError" + e);
            result.error("MDS Exception", null, e);
          }
          @Override
          public void onDisconnect(String macAddress) {
            Log.d("MovesenseFlutterPlugin", "mds.connect onDisconnect: " + macAddress);
            // do not write the result, it has already been sent
          }
        }
      );
    } else if (call.method.equals("connected")) {
      mds.get("suunto://MDS/ConnectedDevices", null,
        new MdsResponseListener() {
          @Override
          public void onSuccess(String data) {
            Log.d("MovesenseFlutterPlugin", data);
            result.success(200);
          }
          @Override
          public void onError(MdsException e) {
            Log.e("MovesenseFlutterPlugin", "Error getting connected devices", e);
            result.error("MDS Exception", "could not GET suunto://MDS/ConnectedDevices", e);
          }
        } // MdsResponseListener
      ); // mds.get
    } else if (call.method.equals("disconnect")) {
      Log.d("MovesenseFlutterPlugin",String.format("disconnecting from Movesense at MAC address %s", mac));
      if (mac != null && !mac.isEmpty()) {
        mds.disconnect(mac);
        result.success(200);
      } else {
        result.error("MAC address is null or empty", null, null);
      }
    } else if (call.method.equals("get")) {
      mds.get(String.format("suunto://%d%s",serial,path), // TODO: better than String.format
        null,
        new MdsResponseListener() {
          @Override
          public void onSuccess(String data) {
            Log.d("MovesenseFlutterPlugin", String.format("received whiteboard response of type %s:", data.getClass().getName()));
            Log.d("MovesenseFlutterPlugin", data);
            result.success(data);
          }
          @Override
          public void onError(MdsException e) {
            result.error("MDS Exception", null, e);
          }
        } // MdsResponseListener
      ); // mds.get
    } else if (call.method.equals("put")) {
      final String value = call.argument("value");
      // mds.put(path, json.encode(value),
      mds.put(path, value,
        new MdsResponseListener() {
          @Override
          public void onSuccess(String data) {
            Log.d("MovesenseFlutterPlugin", data);
            result.success(data);
          }
          @Override
          public void onError(MdsException e) {
            result.error("MDS Exception", null, e);
          }
        } // MdsResponseListener
      ); // mds.put
    } else if (call.method.equals("post")) {
      result.notImplemented();
    } else if (call.method.equals("delete")) {
      result.notImplemented();
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }
}
