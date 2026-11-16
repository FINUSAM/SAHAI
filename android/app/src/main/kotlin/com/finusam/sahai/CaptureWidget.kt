package com.finusam.sahai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * The "Capture a thought" home-screen widget (M6 frame 13, AT-099). A fixed
 * layout whose tap opens [CaptureActivity]. It shows no data, so it never
 * needs updating after it's placed (decision 0007).
 */
class CaptureWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, CaptureActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val views = RemoteViews(context.packageName, R.layout.capture_widget).apply {
            setOnClickPendingIntent(R.id.capture_widget_root, open)
        }
        for (id in ids) manager.updateAppWidget(id, views)
    }
}
