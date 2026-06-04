package com.example.ui

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.graphics.drawable.toBitmap
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class AppInfo(
    val packageName: String,
    val appName: String,
    val iconBitmap: ImageBitmap?
)

class PerAppViewModel(application: Application) : AndroidViewModel(application) {

    private val prefs = application.getSharedPreferences("abdal_vpn_prefs", Context.MODE_PRIVATE)

    private val _installedApps = MutableStateFlow<List<AppInfo>?>(null)
    val installedApps: StateFlow<List<AppInfo>?> = _installedApps

    // true = Bypass Tunnel (exclude selected), false = Route via Tunnel (include selected)
    private val _isBypassMode = MutableStateFlow(prefs.getBoolean("per_app_bypass_mode", true))
    val isBypassMode: StateFlow<Boolean> = _isBypassMode

    private val _selectedApps = MutableStateFlow(
        prefs.getStringSet("per_app_selected_apps", emptySet()) ?: emptySet()
    )
    val selectedApps: StateFlow<Set<String>> = _selectedApps

    fun setMode(isBypass: Boolean) {
        _isBypassMode.value = isBypass
        prefs.edit().putBoolean("per_app_bypass_mode", isBypass).apply()
    }

    fun toggleAppSelection(packageName: String, isSelected: Boolean) {
        val current = _selectedApps.value.toMutableSet()
        if (isSelected) {
            current.add(packageName)
        } else {
            current.remove(packageName)
        }
        _selectedApps.value = current
        prefs.edit().putStringSet("per_app_selected_apps", current).apply()
    }

    fun loadInstalledApps() {
        if (_installedApps.value != null) return
        viewModelScope.launch(Dispatchers.IO) {
            val pm = getApplication<Application>().packageManager
            val packages = pm.getInstalledPackages(PackageManager.GET_META_DATA)
            val apps = packages.mapNotNull { packageInfo ->
                val intent = pm.getLaunchIntentForPackage(packageInfo.packageName)
                if (intent != null && packageInfo.packageName != getApplication<Application>().packageName) {
                    val appInfoObj = packageInfo.applicationInfo
                    if (appInfoObj != null) {
                        val iconDrawable = appInfoObj.loadIcon(pm)
                        val bitmap = try {
                            iconDrawable.toBitmap().asImageBitmap()
                        } catch (e: Exception) {
                            try {
                                iconDrawable.toBitmap(144, 144).asImageBitmap()
                            } catch (e2: Exception) {
                                null
                            }
                        }
                        AppInfo(
                            packageName = packageInfo.packageName,
                            appName = appInfoObj.loadLabel(pm).toString(),
                            iconBitmap = bitmap
                        )
                    } else null
                } else null
            }.sortedBy { it.appName.lowercase() }.distinctBy { it.packageName }
            _installedApps.value = apps
        }
    }
}
