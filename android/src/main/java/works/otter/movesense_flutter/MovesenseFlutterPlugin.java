package works.otter.movesense_flutter;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.content.Context;
import android.util.Log;

import com.movesense.mds.Mds;
import com.movesense.mds.MdsConnectionListener;
import com.movesense.mds.MdsException;
import com.movesense.mds.MdsResponseListener;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import org.json.simple.JSONObject;
import io.reactivex.Observable;
import io.reactivex.disposables.Disposable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import com.polidea.rxandroidble2.RxBleClient;
import com.polidea.rxandroidble2.RxBleDevice;
import com.polidea.rxandroidble2.scan.ScanFilter;
import com.polidea.rxandroidble2.scan.ScanResult;
import com.polidea.rxandroidble2.scan.ScanSettings;

public class MovesenseFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "MovesenseFlutterPlugin";
  private Context context = null;
  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private static Mds mds;
  private static RxBleClient ble;
  private static Disposable sub;

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
    mds = Mds.builder().build(this.context);
    ble = RxBleClient.create(this.context);
    methodChannel = new MethodChannel(messenger, "otter.works/movesense/whiteboard");
    methodChannel.setMethodCallHandler(this);
    eventChannel = new EventChannel(messenger, "otter.works/movesense/scan");
    eventChannel.setStreamHandler(
      new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object o, final EventChannel.EventSink event) {
          Log.d(TAG, "adding stream listener");
          Hashtable<String, String> mac_name = new Hashtable<String, String>();
          sub = ble.scanBleDevices(
          new ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build() //,
        )
          .subscribe(
            scanResult -> {
              if (scanResult.getBleDevice() != null) {
                RxBleDevice device = scanResult.getBleDevice();
                if (device.getName() != null) { // && device.getName().startsWith("Movesense")) {
                  if (mac_name.get(device.getMacAddress()) == null) {
                    Log.d(TAG, "found " + device.getName() + " with MAC " + device.getMacAddress());
                    mac_name.put(device.getMacAddress(), device.getName());
                    JSONObject json = new JSONObject();
                    json.putAll(mac_name);
                    event.success(json.toString());
                  }
                }
              }
            },
            throwable -> {
              Log.e(TAG,"scan error: " + throwable);
              event.error("STREAM", "Error processing scan subscription", throwable.getMessage());
            },
            () -> Log.d(TAG, "closing the scan subscription")
          );

        }

        @Override
        public void onCancel(Object o) {
          Log.d(TAG, "cancelling stream listener");
          if (sub == null) {
            Log.d(TAG, "stream listener subscription already cancelled");
          } else {
            sub.dispose();
            sub = null;
          }
        }
      }
    );
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) { // TODO: revisit final modifier
    final String path = call.argument("path");
// TODO: seems like get/put/post/delete below are boilerplate and I should be able to implement them with some sort of function factory, but let's stick with the simple boilerplate for now
    switch (call.method) {
      case "connect": {
        final String mac = call.argument("mac");
        if (sub != null) {
          sub.dispose();
          sub = null;
          Log.d(TAG, "stopped BLE scan before connecting");
        }
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
        Log.wtf(TAG, String.format("Yo! %s is not a valid MDS Whiteboard action.", call.method));
        result.notImplemented();
      }
    } // switch
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
}

