# YREyeDistance

[![CI Status](https://img.shields.io/travis/yiren/YREyeDistance.svg?style=flat)](https://travis-ci.org/yiren/YREyeDistance)
[![Version](https://img.shields.io/cocoapods/v/YREyeDistance.svg?style=flat)](https://cocoapods.org/pods/YREyeDistance)
[![License](https://img.shields.io/cocoapods/l/YREyeDistance.svg?style=flat)](https://cocoapods.org/pods/YREyeDistance)
[![Platform](https://img.shields.io/cocoapods/p/YREyeDistance.svg?style=flat)](https://cocoapods.org/pods/YREyeDistance)

一个简单计算人眼到屏幕的方法

## Example

代码很简单直接看demo
cocoapods库只是一个简单的封装，实现实际上相当简单，但是应用场景大不相同，很多情况可能无法直接使用

## Requirements
iOS 12.0

## Installation

```ruby
pod 'YREyeDistance'
```
## 关于实现
### 使用ARKit获取

带有faceid的设备可以直接使用ARKit获取准确的人眼到屏幕距离。
主要依赖 `ARKit`和`SceneKit`

利用提供的`SCNNode`的XYZ属性来计算距离，`眼球的node.worldPosition - 原点(SCNVector3Zero)`。
左眼和右眼距离平均之后可以得到一个较为准确的距离数字，而且对偏头转头的计算也比较准确。

```js
let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero

//计算左右平均距离
let averageDistance = (leftEyeDistanceFromCamera.length() + rightEyeDistanceFromCamera.length()) / 2
```

length()是xyz平方开根号
node相减也是类似
```js
extension SCNVector3{
    //The Length Of Vector
    func length() -> Float { return sqrtf(x * x + y * y + z * z) }
    //Subtract Two SCNVector3's
    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 { return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z) }
}
```
缺点也比较明显，耗电不少，同时需要建立一个`ARSCNView`,可用设备也受限制需要faceid。

创建`ARSCNView`

```js
        //设备不支持
        if !checkARSupport() {
            return
        }

        if !checkCameraPermission() {
            print("无相机权限")
            return
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true

        self.sceneView.delegate = self
        self.sceneView.showsStatistics = true
        self.sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

```
设置眼球`SCNNode`

```swift
func setupEyeNode() {
        let eyeGeometry = SCNSphere(radius: 0.005)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.green
        eyeGeometry.materials.first?.transparency = 1.0
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1

        leftEye = node.clone()
        rightEye = node.clone()
    }
```

在`ARSCNView`的delegate中添加node，以及更新脸部数据。
添加node
```js
func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //处理node
        //setup node eye and face
        self.faceNode = node
        guard let device = self.sceneView.device else { return }
        let faceGeo = ARSCNFaceGeometry(device: device)
        self.faceNode.geometry = faceGeo
//        self.faceNode.geometry?.firstMaterial?.fillMode = .lines

        self.faceNode.addChildNode(self.leftEye)
        self.faceNode.addChildNode(self.rightEye)
        self.faceNode.transform = node.transform
    }
```

更新数据

```js
func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            self.faceNode.transform = node.transform
            self.faceNode.geometry?.materials.first?.diffuse.contents = UIColor.yellow
            //update node
            guard let faceAnchor = anchor as? ARFaceAnchor else {
                //没找到人脸
                print("NO FACE")
                return
            }

            //脸部数据
            if let faceGeo = node.geometry as? ARSCNFaceGeometry {
                faceGeo.update(from: faceAnchor.geometry)
            }
            leftEye.simdTransform = faceAnchor.leftEyeTransform
            rightEye.simdTransform = faceAnchor.rightEyeTransform
            //获取距离
            trackDistance()
    }
```
最终计算人眼距离

```js
func trackDistance() {
        DispatchQueue.main.async {
            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero

            //计算左右平均距离
            let averageDistance = (leftEyeDistanceFromCamera.length() + rightEyeDistanceFromCamera.length()) / 2
            let averageDistanceCM = averageDistance * 100
        }
    }
```
通过左眼和右眼分别减去相机node得到距离平均之后就可以得到人眼距离。

以上为使用`ARKit`获取人眼距离的方法。

### 使用Vision

在普通设备不支持ARKit或者需要占用摄像头的业务中，可以使用`Vision`来计算。不同设备的摄像头参数会有不同，比如ccd尺寸，焦距等。这边需要了解一个概念：[等效焦距](https://baike.baidu.com/item/35mm%E7%AD%89%E6%95%88%E7%84%A6%E8%B7%9D/15541766?fr=aladdin)

对于不同的焦距我们都可以换算出35mm等效焦距来计算(35 mm equivalent focal length)。
等效焦距目前iOS没有很好的API可以直接获取，目前可以通过拍摄照片取得照片exif信息，其中的`FocalLenIn35mmFilm`来获取35mm等效焦距。


### 计算原理
这边以双眼距离(瞳距)为基础，这边是个平均值，每个人都会有不同。成人大约63mm，儿童的话随着年龄会有变化。
儿童的双眼距离目前没有一个很好的平均数据，参考[一个眼镜网站](https://tomatoglasses.me/pages/sizing-advice)的数据。

![How_to_measure_PD_real_person._large_9488a286-add6-4be6-a5a9-9c70836e6857.jpg](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/db9052f1f9ea42ffae7e57903f9e1ace~tplv-k3u1fbpfcp-watermark.image)

```js
if age < 4 && age > 0 { //0 - 4
    return 45
}else if age >= 4 && age <= 7 { // 4 - 7
    return 50
}else if age >= 8 && age <= 11 {// 8 - 11
    return 56
}else if age >= 12 && age <= 16 {//12 - 16
    return 59
}else if age > 16 { // > 17
    return 63
}

```

这边计算主要用到2个光学公式，有点像小孔成像吧

```js
光学公式
1/物距 + 1/像距 = 1/焦距 
像高/像距 = 物高/物距 
```

### 计算示例

在等效焦距下， 成像面积可以认为是 36mm * 24mm。
假设屏幕像素 为1920 * 1080。

```js
距离 = ( 1 + 63 * 1080 / 24 / 双眼像素距离 ) * 等效焦距 
```
实际计算中还会取一个FOV(feild of view)比例, FOV以及像素等可以使用 `AVCaptureDevice.format`
里面会有很多目前使用的格式数据。
```js
format resolution = <AVCaptureDeviceFormat: 0x2817f4130 'vide'/'420v' 1920x1080, { 1- 30 fps}, HRSI:3392x1908, fov:61.161, supports vis, max zoom:16.00 (upscales @1.61), ISO:18.0-1728.0, SS:0.000020-1.000000, supports HDR, supports multicam>
```

实际计算

```js
distance = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.width) / 24 / (self.eyeDistance)) * self.fLength / 10.0 * self.fovFactor
```

`previewLayer!.frame.width`  摄像头preview宽度 

`eyeDistance` 双眼像素距离

`fLength` 等效焦距

`realEyeDistance`双眼真实瞳距(上面63mm)，这个是我们所有计算的基础。

`fovFactor` fov比例 从上述format获取
fov比例计算如下

```swift
func processFOV(device: AVCaptureDevice) {
        let currentFOV = device.activeFormat.videoFieldOfView

        if let basicFov = device.formats.last?.videoFieldOfView {
            self.fovFactor = currentFOV / basicFov
        }
    }
```

#### 关于fLength等效焦距
使用过多个苹果设备 各种iPhone和iPad拍照后取数据发现大部分设备在30-32之间，个别在29
这边也没有使用映射表根据设备取值，理论上这样应该更准确。这边`fLength`取平均31

#### 偏头计算
有一个很明显的问题就是大多数时候你不会直视摄像头，那么双眼和摄像头之间就会有一个角度。理论上我们应该要去计算这个，但是目前是没有计算的，偏转只会是检测的距离偏大。
苹果提供了一套偏转角度YAW，很可惜没法直接使用，因为区间太大。

`face.yaw!.floatValue`yaw的范围在-90 到 90。但是灵敏度太低，只有很大的数值比如-90, -45, 0, 45, 90。所以如果使用这个计算也是不准确的。

#### 人脸数据
这边使用Vision框架来提取人脸数据。

```swift
       let handler = VNImageRequestHandler(cgImage: image, orientation: .downMirrored, options: [:])
        let faceRequest = VNDetectFaceLandmarksRequest.init { [weak self] (vnRequest, _) in
            if let result = vnRequest.results as? [VNFaceObservation] {
                self?.processLandmarks(faces: result)
            } else {
            }
        }
        
        //降低CPU/GPU使用
        faceRequest.preferBackgroundProcessing = true
        try? handler.perform([faceRequest])
```

通过把帧数据（`cgImage`或者`CVPixelBuffer`）创建`VNDetectFaceLandmarksRequest`，检测之后可以得到一个包含`VNFaceObservation`的数组

拿到数据之后我可以可以看看是否包含人脸，然后就可以进行计算了

```swift
        guard let preview = self.previewLayer else {return}

        //默认第一张脸
        let firstFace = faces[0]
        
        //画布相关比例
        var faceBoxOnscreen = preview.layerRectConverted(fromMetadataOutputRect: firstFace.boundingBox)

        if !useCamera {
            faceBoxOnscreen = CGRect(x: preview.frame.width * firstFace.boundingBox.origin.y, y: preview.frame.height * firstFace.boundingBox.origin.x, width: preview.frame.width * firstFace.boundingBox.size.height, height: preview.frame.height * firstFace.boundingBox.size.width)
        }

        let x = faceBoxOnscreen.origin.x
        let y = faceBoxOnscreen.origin.y
        let w = faceBoxOnscreen.size.width
        let h = faceBoxOnscreen.size.height

        //左眼球
        if let leftPupil = firstFace.landmarks?.leftPupil {
            //右眼球
            if let rightPupil = firstFace.landmarks?.rightPupil {
                guard let leftEyePoint = leftPupil.normalizedPoints.first else { return}
                guard let rightEyePoint = rightPupil.normalizedPoints.first else { return }

                let leftX = leftEyePoint.y * h + x
                let rightX = rightEyePoint.y * h + x
                let leftY = leftEyePoint.x * w + y
                let rightY = rightEyePoint.x * w + y
                self.eyeDistance = sqrtf(powf(Float(leftX - rightX), 2) + powf(Float(leftY - rightY), 2))
            }
        }
```

`useCamera`这个参数解释一下
我们可以有俩种情况，一是我们自己启动摄像头，那么显示区域和画面都是自己控制直接获取就可以了。
第二种情况是画布我们创建，但是摄像头是外部控制，只是传入帧数据给我们。那么我们需要进行一些转换。
其他的计算应该都很好理解。

最后我们判断一下**横竖屏**就可以得到**人眼距离**了

```js
        if UIDevice.current.orientation.isLandscape {
            distance = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.width) / 24 / (self.eyeDistance)) * self.fLength / 10.0 * self.fovFactor
        } else {
            distance = (1.0 + self.realEyeDistance * Float(self.previewLayer!.frame.height) / 36 / (self.eyeDistance)) * self.fLength / 10.0 * self.fovFactor
        }
```

这边的`realEyeDistance`指的是瞳距，成人的话目前取值`63mm`也是平均值。
这样的话可以粗略得到人眼距离了。
老旧设备还有一个性能问题，由于是持续不断的检测人眼距离。那么检测频率可以控制一下，比如20帧检测一次，或者屏蔽一下过于老旧的设备比如iPhone5s以下，iPad Air一代以下。

头部偏转角度计算目前还没有做，暂时没想到很好的方法，看看后续有机会能优化一下。

## Author

daQiuQiu

## License

YREyeDistance is available under the MIT license. See the LICENSE file for more info.
