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

import com.movesense.mds.Mds;
import com.movesense.mds.MdsException;
import com.movesense.mds.MdsResponseListener;

public class MovesenseFlutterPlugin implements FlutterPlugin, MethodCallHandler {
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
    // TODO: Get the serial number for the Movesense Device we are connected to.
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) { // TODO: revisit final modifier
    final String path = call.argument("path");
    if (call.method.equals("get")) {
      mds.get(path, null,
        new MdsResponseListener() {
          @Override
          public void onSuccess(String data) {
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
