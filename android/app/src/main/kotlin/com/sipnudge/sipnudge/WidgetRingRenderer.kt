package com.sipnudge.sipnudge

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import androidx.core.content.res.ResourcesCompat

object WidgetRingRenderer {

    private var urbanistBold: Typeface? = null

    private fun getUrbanistBold(context: Context?): Typeface {
        if (urbanistBold != null) return urbanistBold!!
        if (context != null) {
            try {
                val tf = ResourcesCompat.getFont(context, R.font.urbanist_extrabold)
                    ?: ResourcesCompat.getFont(context, R.font.urbanist)
                if (tf != null) {
                    urbanistBold = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        Typeface.create(tf, 800, false)
                    } else {
                        Typeface.create(tf, Typeface.BOLD)
                    }
                    return urbanistBold!!
                }
            } catch (_: Exception) {}
            try {
                val tf = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Urbanist-VariableFont_wght.ttf")
                if (tf != null) {
                    urbanistBold = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        Typeface.create(tf, 800, false)
                    } else {
                        Typeface.create(tf, Typeface.BOLD)
                    }
                    return urbanistBold!!
                }
            } catch (_: Exception) {}
        }
        urbanistBold = Typeface.create("sans-serif", Typeface.BOLD)
        return urbanistBold!!
    }

    fun renderGauge(
        progress: Double,
        expectedPercent: Double,
        percentageString: String,
        recentAddedAmount: Int?,
        context: Context? = null,
        sizePx: Int = 360
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Sleek proportionate stroke width (clean elegant ring)
        val strokeWidth = sizePx * 0.092f
        val padding = strokeWidth / 2f + 4f
        val oval = RectF(padding, padding, sizePx - padding, sizePx - padding)

        // In iOS: Circle().trim(from: 0.0, to: 0.833).rotationEffect(Angle(degrees: 300))
        // Starts at 300 degrees (1 o'clock) and sweeps 300 degrees clockwise (leaving 60 deg gap at 12 o'clock)
        val startAngle = 300f
        val maxSweep = 300f

        // 1. Background track arc
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.ROUND
            color = Color.parseColor("#EBEEF2")
        }
        canvas.drawArc(oval, startAngle, maxSweep, false, trackPaint)

        // 2. Expected schedule target arc (Amber/Yellow #F5B91E)
        if (expectedPercent > 0) {
            val sweepTarget = (Math.min(expectedPercent / 100.0, 1.0) * maxSweep).toFloat()
            if (sweepTarget > 0) {
                val targetPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    strokeCap = Paint.Cap.ROUND
                    color = Color.parseColor("#F5B91E")
                }
                canvas.drawArc(oval, startAngle, sweepTarget, false, targetPaint)
            }
        }

        // 3. Actual water intake progress arc (Gradient Blue #B4D9FF to #1C8DBB)
        if (progress > 0) {
            val sweepActual = (Math.min(progress, 1.0) * maxSweep).toFloat()
            if (sweepActual > 0) {
                val gradient = LinearGradient(
                    sizePx / 2f, 0f,
                    sizePx / 2f, sizePx.toFloat(),
                    Color.parseColor("#B4D9FF"),
                    Color.parseColor("#1C8DBB"),
                    Shader.TileMode.CLAMP
                )
                val actualPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    this.strokeWidth = strokeWidth
                    strokeCap = Paint.Cap.ROUND
                    shader = gradient
                }
                canvas.drawArc(oval, startAngle, sweepActual, false, actualPaint)
            }
        }

        // 4. Center Text: Percentage & Optional "+ xxx ml" indicator in Urbanist font
        val urbanistTf = getUrbanistBold(context)
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            color = Color.parseColor("#172645")
            textAlign = Paint.Align.CENTER
            typeface = urbanistTf
            letterSpacing = -0.02f
        }

        val centerX = sizePx / 2f
        val centerY = sizePx / 2f

        if (recentAddedAmount != null && recentAddedAmount > 0) {
            textPaint.textSize = sizePx * 0.22f
            canvas.drawText(percentageString, centerX, centerY - sizePx * 0.04f, textPaint)

            val badgePaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
                color = Color.parseColor("#A37A52")
                textAlign = Paint.Align.CENTER
                textSize = sizePx * 0.11f
                typeface = urbanistTf
            }
            canvas.drawText("+$recentAddedAmount ml", centerX, centerY + sizePx * 0.16f, badgePaint)
        } else {
            textPaint.textSize = sizePx * 0.28f
            val yPos = centerY - (textPaint.descent() + textPaint.ascent()) / 2
            canvas.drawText(percentageString, centerX, yPos, textPaint)
        }

        return bitmap
    }

    fun getBatteryColor(battery: Int): Int {
        return when {
            battery < 20 -> Color.parseColor("#EF4444") // Red
            battery < 50 -> Color.parseColor("#FFA500") // Orange
            else -> Color.parseColor("#10B981") // Green
        }
    }

    fun renderBatteryBar(battery: Int, widthPx: Int = 300, heightPx: Int = 16): Bitmap {
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val radius = heightPx / 2f
        val color = getBatteryColor(battery)

        // Track background
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = Color.parseColor("#EBEEF2")
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()), radius, radius, bgPaint)

        // Active progress fill
        val clampedPct = Math.min(Math.max(battery, 0), 100)
        if (clampedPct > 0) {
            val fillWidth = Math.max(radius * 2f, (clampedPct / 100f) * widthPx)
            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(RectF(0f, 0f, fillWidth, heightPx.toFloat()), radius, radius, fillPaint)
        }

        return bitmap
    }

    fun renderBatteryIcon(battery: Int, widthPx: Int = 48, heightPx: Int = 28): Bitmap {
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val color = getBatteryColor(battery)
        val strokeWidth = 3f

        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
        }

        // Body outline
        val bodyWidth = widthPx - 8f
        val bodyRect = RectF(strokeWidth / 2f, strokeWidth / 2f, bodyWidth - strokeWidth / 2f, heightPx - strokeWidth / 2f)
        canvas.drawRoundRect(bodyRect, 6f, 6f, strokePaint)

        // Terminal nub on the right
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }
        val nubLeft = bodyWidth + 1f
        val nubTop = heightPx * 0.28f
        val nubBottom = heightPx * 0.72f
        val nubRect = RectF(nubLeft, nubTop, widthPx - 1f, nubBottom)
        canvas.drawRoundRect(nubRect, 2f, 2f, fillPaint)

        // Inner charge fill
        val clampedPct = Math.min(Math.max(battery, 0), 100)
        if (clampedPct > 0) {
            val fillMargin = strokeWidth + 2f
            val maxInnerWidth = (bodyWidth - fillMargin * 2f)
            val fillW = Math.max(2f, maxInnerWidth * (clampedPct / 100f))
            val innerRect = RectF(fillMargin, fillMargin, fillMargin + fillW, heightPx - fillMargin)
            canvas.drawRoundRect(innerRect, 3f, 3f, fillPaint)
        }

        return bitmap
    }
}
