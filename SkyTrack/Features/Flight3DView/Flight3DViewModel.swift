import Foundation
import SceneKit
import CoreLocation
import os

/// ViewModel for 3D flight visualization with terrain rendering.
@Observable
final class Flight3DViewModel {
    var scene: SCNScene
    var cameraNode: SCNNode
    var flightNode: SCNNode?
    var terrainNode: SCNNode?
    var pathNodes: [SCNNode] = []

    var flight: Flight?
    var viewMode: ViewMode = .following
    var isPlaying = true

    private var displayLink: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "3d-view")

    enum ViewMode: String, CaseIterable {
        case following = "Following"
        case cockpit = "Cockpit"
        case topDown = "Top Down"
        case freeCamera = "Free Camera"
    }

    init() {
        scene = SCNScene()
        cameraNode = SCNNode()
        setupScene()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        // Camera
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 500
        camera.fieldOfView = 60
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 5, 15)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)

        // Directional light (sun)
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.intensity = 800
        sunLight.light?.castsShadow = true
        sunLight.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        scene.rootNode.addChildNode(sunLight)

        // Sky
        scene.background.contents = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1)

        // Ground plane (terrain placeholder)
        addTerrainPlane()
    }

    // MARK: - Terrain

    private func addTerrainPlane() {
        let ground = SCNPlane(width: 200, height: 200)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1)
        material.roughness.contents = 0.8
        ground.materials = [material]

        let node = SCNNode(geometry: ground)
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, -0.1, 0)
        scene.rootNode.addChildNode(node)
        terrainNode = node
    }

    // MARK: - Aircraft

    func loadFlight(_ flight: Flight) {
        self.flight = flight
        flightNode?.removeFromParentNode()

        // Build aircraft model
        let aircraft = buildAircraftNode()
        scene.rootNode.addChildNode(aircraft)
        flightNode = aircraft

        // Set initial position
        if let live = flight.liveData {
            let altitude = Float(live.altitude / 1000) // Scale down
            aircraft.position = SCNVector3(0, max(altitude, 0.5), 0)
            aircraft.eulerAngles.y = Float(live.heading * .pi / 180)
        }

        // Build flight path
        buildFlightPath(flight)

        // Update camera
        updateCamera()

        Self.logger.info("Loaded 3D view for \(flight.displayName)")
    }

    private func buildAircraftNode() -> SCNNode {
        let container = SCNNode()

        // Fuselage
        let fuselage = SCNCapsule(capRadius: 0.15, height: 2.0)
        let fuselageMaterial = SCNMaterial()
        fuselageMaterial.diffuse.contents = UIColor.white
        fuselageMaterial.metalness.contents = 0.3
        fuselage.materials = [fuselageMaterial]
        let fuselageNode = SCNNode(geometry: fuselage)
        fuselageNode.eulerAngles.z = .pi / 2
        container.addChildNode(fuselageNode)

        // Wings
        let wing = SCNBox(width: 3.0, height: 0.03, length: 0.5, chamferRadius: 0.01)
        let wingMaterial = SCNMaterial()
        wingMaterial.diffuse.contents = UIColor.lightGray
        wingMaterial.metalness.contents = 0.4
        wing.materials = [wingMaterial]
        let wingNode = SCNNode(geometry: wing)
        wingNode.position = SCNVector3(0, 0, -0.1)
        container.addChildNode(wingNode)

        // Tail fin
        let tail = SCNBox(width: 0.03, height: 0.6, length: 0.3, chamferRadius: 0.01)
        let tailMaterial = SCNMaterial()
        tailMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1) // Airline blue
        tail.materials = [tailMaterial]
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.3, -0.85)
        container.addChildNode(tailNode)

        // Horizontal stabilizer
        let hStab = SCNBox(width: 1.0, height: 0.02, length: 0.25, chamferRadius: 0.005)
        hStab.materials = [wingMaterial]
        let hStabNode = SCNNode(geometry: hStab)
        hStabNode.position = SCNVector3(0, 0, -0.85)
        container.addChildNode(hStabNode)

        // Engines
        for xOffset: Float in [-0.7, 0.7] {
            let engine = SCNCylinder(radius: 0.1, height: 0.4)
            let engineMaterial = SCNMaterial()
            engineMaterial.diffuse.contents = UIColor.darkGray
            engineMaterial.metalness.contents = 0.6
            engine.materials = [engineMaterial]
            let engineNode = SCNNode(geometry: engine)
            engineNode.eulerAngles.z = .pi / 2
            engineNode.position = SCNVector3(xOffset, -0.15, 0.1)
            container.addChildNode(engineNode)
        }

        container.scale = SCNVector3(0.5, 0.5, 0.5)
        return container
    }

    // MARK: - Flight Path

    private func buildFlightPath(_ flight: Flight) {
        pathNodes.forEach { $0.removeFromParentNode() }
        pathNodes.removeAll()

        // Departure marker
        let depMarker = buildAirportMarker(color: .green, label: flight.departure.displayCode)
        depMarker.position = SCNVector3(-8, 0, 0)
        scene.rootNode.addChildNode(depMarker)
        pathNodes.append(depMarker)

        // Arrival marker
        let arrMarker = buildAirportMarker(color: .red, label: flight.arrival.displayCode)
        arrMarker.position = SCNVector3(8, 0, 0)
        scene.rootNode.addChildNode(arrMarker)
        pathNodes.append(arrMarker)

        // Flight path line (great circle arc)
        let points = buildArcPoints(from: SCNVector3(-8, 0.5, 0), to: SCNVector3(8, 0.5, 0), segments: 50)
        let pathGeometry = buildPathGeometry(points: points)
        let pathNode = SCNNode(geometry: pathGeometry)
        scene.rootNode.addChildNode(pathNode)
        pathNodes.append(pathNode)
    }

    private func buildAirportMarker(color: UIColor, label: String) -> SCNNode {
        let container = SCNNode()

        // Pin
        let sphere = SCNSphere(radius: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color.withAlphaComponent(0.3)
        sphere.materials = [material]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0.2, 0)
        container.addChildNode(sphereNode)

        // Label
        let text = SCNText(string: label, extrusionDepth: 0.02)
        text.font = UIFont.monospacedSystemFont(ofSize: 0.3, weight: .bold)
        text.flatness = 0.1
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.white
        text.materials = [textMaterial]
        let textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(1, 1, 1)
        textNode.position = SCNVector3(-0.3, 0.6, 0)
        container.addChildNode(textNode)

        return container
    }

    private func buildArcPoints(from: SCNVector3, to: SCNVector3, segments: Int) -> [SCNVector3] {
        var points: [SCNVector3] = []
        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let x = from.x + (to.x - from.x) * t
            let arcHeight: Float = 5.0 * sin(t * .pi) // Parabolic arc
            let y = max(from.y, to.y) + arcHeight
            let z = from.z + (to.z - from.z) * t
            points.append(SCNVector3(x, y, z))
        }
        return points
    }

    private func buildPathGeometry(points: [SCNVector3]) -> SCNGeometry {
        var indices: [Int32] = []
        for i in 0..<points.count - 1 {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }

        let source = SCNGeometrySource(vertices: points)
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.7)
        material.isDoubleSided = true
        geometry.materials = [material]

        return geometry
    }

    // MARK: - Camera Modes

    func updateCamera() {
        guard let aircraft = flightNode else { return }

        switch viewMode {
        case .following:
            cameraNode.position = SCNVector3(
                aircraft.position.x - 3,
                aircraft.position.y + 2,
                aircraft.position.z + 5
            )
            cameraNode.look(at: aircraft.position)

        case .cockpit:
            cameraNode.position = SCNVector3(
                aircraft.position.x + 0.5,
                aircraft.position.y + 0.1,
                aircraft.position.z
            )
            cameraNode.eulerAngles = aircraft.eulerAngles

        case .topDown:
            cameraNode.position = SCNVector3(0, 15, 0)
            cameraNode.look(at: SCNVector3(0, 0, 0))

        case .freeCamera:
            break // User controls
        }
    }

    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
        updateCamera()
    }
}
