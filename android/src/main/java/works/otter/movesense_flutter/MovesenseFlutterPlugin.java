package works.otter.movesense_flutter;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.Manifest.permission;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
// import androidx.core.content.PermissionChecker; // TODO: consider migrating

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;

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

public class MovesenseFlutterPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, StreamHandler {
  private static final String TAG = "MovesenseFlutterPlugin";
  private Activity activity = null;
  private Context context = null;
  private EventChannel scanChannel;
  private EventChannel connectionChannel;
  private MethodChannel whiteboardChannel;
  private static Mds mds;
  private static String connectedToSerial = null;
  private static String connectedToMac = null;

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    scanChannel.setStreamHandler(new ScanHandler(this.activity, this.context));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    this.activity = null;
    scanChannel.setStreamHandler(new ScanHandler(this.activity, this.context));
  }
  
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

    scanChannel = new EventChannel(messenger, "otter.works/movesense/scan");
    scanChannel.setStreamHandler(new ScanHandler(this.activity, this.context));

    connectionChannel = new EventChannel(messenger, "otter.works/movesense/connection");
    connectionChannel.setStreamHandler(this);

    whiteboardChannel = new MethodChannel(messenger, "otter.works/movesense/whiteboard");
    whiteboardChannel.setMethodCallHandler(this);

  }

  @Override
  public void onListen(Object o, final EventChannel.EventSink event) {
    Log.d(TAG, "onListen");
    final String mac = String.valueOf(o);
    mds.connect(mac,
      new MdsConnectionListener() {
        @Override
        public void onConnect(String s) {
          Log.d(TAG, "mds.connect onConnect: " + s);
          event.success("connecting");
        }
        @Override
        public void onConnectionComplete(String macAddress, String serialNumber) {
          Log.d(TAG, "mds.connect onConnectionComplete: MAC: " + macAddress + ", serial #: " + serialNumber);
          connectedToMac = macAddress;
          connectedToSerial = serialNumber;
          event.success("connected to MAC: " + macAddress + " serial #: " + serialNumber);
        }
        @Override
        public void onError(MdsException e) {
          Log.e(TAG, "mds.connect onError" + e);
          event.error("MDS Exception", null, e);
        }
        @Override
        public void onDisconnect(String macAddress) {
          Log.d(TAG, "mds.connect onDisconnect: " + macAddress);
          connectedToMac = null;
          event.success("disconnected");
        }
      }
    );
  } // onListen

  @Override
  public void onCancel(Object o) {
    Log.d(TAG, "onCancel");
    final String mac = String.valueOf(o);
    mds.disconnect(mac);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) { // TODO: revisit final modifier
    if (connectedToMac == null) {
      Log.wtf(TAG, String.format("unable to call method %s, MDS not connected", call.method));
      result.error(TAG, null, "MDS not connected");
    } else {
    final String path = call.argument("path");
    String pathSerial = path.split("/")[1];
    if (pathSerial == "MDS") {
      pathSerial = path.split("/")[3];
    }
    if (pathSerial == "null" ) {
      Log.wtf(TAG, "received method call with null serial number");
      result.error("404", TAG, "will not attempt transaction with null serial number");
    } else {
      Log.d(TAG, String.format("operation: %s, path: %s", call.method, path));
// TODO: seems like get/put/post/delete below are boilerplate and I should be able to implement them with some sort of function factory, but let's stick with the simple boilerplate for now
      switch (call.method) {
      case "get": {
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
              result.error(String.format("%d", e.getStatusCode()), "MdsException", e.getMessage() + String.format(", path: %s", path));
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
              result.error(String.format("%d", e.getStatusCode()), "MdsException", e.getMessage() + String.format(", path: %s, contract: %s", path, contract));
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
              result.error(String.format("%d", e.getStatusCode()), "MdsException", e.getMessage() + String.format(", path: %s", path));
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
              result.error(String.format("%d", e.getStatusCode()), "MdsException", e.getMessage() + String.format(", path: %s", path));
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
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}
}

class ScanHandler implements StreamHandler {

  private static final String TAG = "MovesenseFlutterPlugin:ScanHandler";
  private Activity activity = null;
  private Context context = null;
  private static Disposable sub = null;
  private static RxBleClient ble;
  private static final int REQUEST_PERMISSION_COARSE_LOCATION = 1;

  public ScanHandler(Activity a, Context c) {
    this.activity = a;
    this.context = c;
    this.ble = RxBleClient.create(this.context);
  }

  public boolean hasCoarseLocationPermission() {
    Log.d(TAG, "checking for coarse location permission");
    if (PackageManager.PERMISSION_DENIED == ContextCompat.checkSelfPermission(context, permission.ACCESS_COARSE_LOCATION)) {
      if (activity != null ) {
        Log.d(TAG, "requesting coarse location permission");
        ActivityCompat.requestPermissions(activity, new String[]{permission.ACCESS_COARSE_LOCATION}, REQUEST_PERMISSION_COARSE_LOCATION);
      } else {
        Log.d(TAG, "could not get reference to activity");
      }
      return false;
    } else {
      Log.d(TAG, "already have coarse location permission");
      return true;
    }
  }

  @Override
  public void onListen(Object o, final EventChannel.EventSink event) {
    Log.d(TAG, "adding stream listener");
    Hashtable<String, String> mac_name = new Hashtable<String, String>();
    if( hasCoarseLocationPermission() ) {
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
          event.error(TAG, "Error processing scan subscription", throwable.getMessage());
        },
        () -> Log.d(TAG, "closing the scan subscription")
      );
    } else {
      Log.e(TAG, "bluetooth/location permission denied");
      event.error(TAG, "Required permissions denied", "Could not get Bluetooth/Location permissions.");
    }
  } // onListen

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
