<div align="center">
  <img alt="myHaystack Logo" src="https://raw.githubusercontent.com/ReLoia/myHaystack/refs/heads/master/assets/myhaystack-icon.png" width="241">
  <h1>myHaystack</h1>
</div>

<div align="center">

_A remake of Macless Haystack (originally OpenHaystack) Mobile App._

</div>

> [!WARNING]  
> This project is not affiliated with Apple Inc. in any way

## What

This application (currently) has the following features:

- seeing items on a map
- importing a key (or multiple keys) from JSON

### Next

- viewing items history
  [#1](https://github.com/ReLoia/myHaystack/issues/1)
- see if a Tracked Item is nearby and add options to get a notification when the items gets "away
  from us"
    - this should be possible to implement, we simpyly need to check every minute or so every BLE
      device nearby, see if our device is still present in the found device list and if not **PANIC
      ** (obviously we need to account that OpenHaystack devices don't continuously broadcast but it
      should still be possible)  
  [#2](https://github.com/ReLoia/myHaystack/issues/2)
- see [the issue page](https://github.com/ReLoia/myHaystack/issues/2)

## Why

I've always loved the work done by the authors of OpenHaystack and MaclessHaystack but I've always
hated the UI of the mobile app.  
After searching for a while I couldn't find a fork or derivate of them that remade the mobile
application (with support to a selfhosted macless-haystack server) so I decided to make one myself.

#### [OpenTagViewer](https://github.com/parawanderer/OpenTagViewer/)

The only derivate of FindMy with a wonderful UI I could find
is [parawanderer/OpenTagViewer](https://github.com/parawanderer/OpenTagViewer/) but it doesn't
support MaclessHaystack.

_I initially wanted to make a fork of them and then PR to them but I wasn't even able to run locally
the app.    
But I decided to give this project a try to learn how to make Flutter apps since I've only got
experience with Kotlin and Android right now._

## Credits

- [dchristl/MaclessHaystack](https://github.com/dchristl/macless-haystack)
  and [seemoo-lab/OpenHaystack](https://github.com/seemoo-lab/openhaystack) - the original projects,
  without them this project wouldn't exist.

- [parawanderer/OpenTagViewer](https://github.com/parawanderer/OpenTagViewer/)  - they are the
  reason I made this app, their UI is wonderful and I wanted to make it compatible with Macless
  Haystack. So I will be taking a lot of inspiration for my flutter widgets.

- [malmeloo/FindMy.py](https://github.com/malmeloo/FindMy.py)  - the reference for the project icon

### Tools used

- [Blockbench](https://web.blockbench.net/) - to make the FindMy.py inspired project icon (I don't
  what did they use but Blockbench really worked well even though I'm not a good artist at all ahah)

- [Icon Kitchen](https://icon.kitchen/) - to generate the assets for android and iOS