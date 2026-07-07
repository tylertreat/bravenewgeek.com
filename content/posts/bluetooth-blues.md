---
title: "Bluetooth Blues"
date: 2013-03-19T16:01:49-06:00
slug: "bluetooth-blues"
categories: ["Android", "Java"]
tags: ["android", "bluetooth", "java", "reflection"]
---

I spent the better part of two days working on Bluetooth connectivity for an Android app I’m developing. Going into it, I had virtually no experience working with Bluetooth, especially on Android. I quickly discovered some of the peculiarities of the platform’s Bluetooth API.

In addition to connecting to Bluetooth devices, the client wanted to pair and unpair from the app. The easy way out, and probably _The Android Way_™, would be to pass that responsibility off to the OS, à la an Intent:

<script src="https://gist.github.com/tylertreat/009c175939d0bff921c0.js"></script>

This will bring up the Bluetooth settings menu, from which you can pair/unpair devices, but the problem is that it’s a complete context switch for the user—they are no longer in your application. I was looking to provide a more seamless experience so that the user didn’t have to leave the app at all to pair a device.

### Device Discovery

The entry point for Bluetooth interaction in Android is through the [BluetoothAdapter](http://developer.android.com/reference/android/bluetooth/BluetoothAdapter.html), which is used to orchestrate the device discovery process and fetch paired devices. Calling startDiscovery() will tell the adapter to start scanning for devices, and when one is found, an Intent will be fired off which can then be intercepted by a BroadcastReceiver.

<script src="https://gist.github.com/tylertreat/afdaf6662267af5245a7.js"></script>

The above code shows how the device discovery process is kicked off and how a BroadcastReceiver is registered to listen for discovery Intents. Note that the BroadcastReceiver is unregistered and discovery is canceled in onDestroy.

In order to react to discovery events, we must implement a BroadcastReceiver.

<script src="https://gist.github.com/tylertreat/a36233736b42a36619aa.js"></script>

### Device Pairing

Once you have a handle on the [BluetoothDevice](http://developer.android.com/reference/android/bluetooth/BluetoothDevice.html) received in the BroadcastHandler, how do you actually pair with it? Looking at the documentation for the class, you’ll see that there are no methods for doing this. This is where things start to get a little strange.

Diving into the [source code](http://grepcode.com/file_/repository.grepcode.com/java/ext/com.google.android/android/2.2_r1.1/android/bluetooth/BluetoothDevice.java/?v=source) for BluetoothDevice, you’ll actually find that there _is_ functionality for doing [pairing](http://grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/2.2_r1.1/android/bluetooth/BluetoothDevice.java#BluetoothDevice.createBond%28%29) and [unpairing](http://grepcode.com/file/repository.grepcode.com/java/ext/com.google.android/android/2.2_r1.1/android/bluetooth/BluetoothDevice.java#BluetoothDevice.removeBond%28%29), but the methods are hidden from the API using the _@hide_ annotation. What’s more interesting is that the methods are, in fact, _public_.

Evidently, device pairing is intended to be performed only by platform applications, which is a little curious considering the permission needed to perform pairing, [android.permission.BLUETOOTH\_ADMIN](http://developer.android.com/reference/android/Manifest.permission.html#BLUETOOTH_ADMIN), is accessible by third-party applications. Nonetheless, this means we actually _can_ pair a BluetoothDevice, just not in the way the Android engineers intended.

To access the BluetoothDevice methods needed, createBond and removeBond, we can use reflection.

<script src="https://gist.github.com/tylertreat/c93c96857f529ed990ea.js"></script>

The pairDevice method will prompt the user to enter a PIN for the discovered device, circumventing the need to open the Bluetooth settings. As such, the pairing does not actually complete until the correct PIN is entered. The boolean value returned from the method indicates whether the pairing process was successfully kicked off or not.

It goes without saying that this code, while functional, is volatile because these methods are technically not part of the public API, so they could change or disappear in future platform releases.

We can add an Intent filter to our BroadcastReceiver to listen for pairing events using the action BluetoothDevice.ACTION\_BOND\_STATE\_CHANGED.

<script src="https://gist.github.com/tylertreat/44c9b8d94f1bf4765d2b.js"></script>

<script src="https://gist.github.com/tylertreat/13102b1f7146d93a3ac9.js"></script>

There are a few other hidden methods in BluetoothDevice, like cancelPairingUserInput, setPairingConfirmation, convertPinToBytes, and setPin, that you could potentially use to customize the pairing process or perform it programmatically, but use them at your own risk.

Once the devices are paired, they can be connected using one of BluetoothDevice’s createRfcommSocketToServiceRecord or createInsecureRfcommSocketToServiceRecord methods after determining the UUID to use, either with getUuids or fetchUuidsWithSdp (or, in most cases, using the well-known UUID 00001101-0000-1000-8000-00805F9B34FB).

It’s very likely that Android’s Bluetooth API is subject to change soon. It already has changed in some of the more recent releases, although I’m not entirely sure why Google isn’t providing a stable API for pairing. Jelly Bean 4.2 introduces a new Bluetooth stack, moving from BlueZ to a Broadcom solution, so my guess is that it’s related to this.
