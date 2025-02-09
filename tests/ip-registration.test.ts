import { describe, it, expect, beforeEach } from "vitest"

// Mock storage for IP registrations
const ipRegistrations = new Map()
let nextIpId = 1

// Mock functions to simulate contract behavior
function registerIp(owner: string, title: string, description: string) {
  const ipId = nextIpId++
  ipRegistrations.set(ipId, { owner, title, description, status: "active" })
  return ipId
}

function updateIpStatus(ipId: number, newStatus: string, sender: string) {
  const ip = ipRegistrations.get(ipId)
  if (!ip) throw new Error("IP not found")
  if (ip.owner !== sender) throw new Error("Unauthorized")
  ip.status = newStatus
  ipRegistrations.set(ipId, ip)
  return true
}

function getIpDetails(ipId: number) {
  return ipRegistrations.get(ipId)
}

function isIpOwner(ipId: number, address: string) {
  const ip = ipRegistrations.get(ipId)
  return ip ? ip.owner === address : false
}

describe("IP Registration Contract", () => {
  beforeEach(() => {
    ipRegistrations.clear()
    nextIpId = 1
  })
  
  it("should register new IP", () => {
    const ipId = registerIp("owner1", "My IP", "Description of my IP")
    expect(ipId).toBe(1)
    const ip = getIpDetails(ipId)
    expect(ip).toBeDefined()
    expect(ip.title).toBe("My IP")
    expect(ip.status).toBe("active")
  })
  
  it("should update IP status", () => {
    const ipId = registerIp("owner1", "My IP", "Description of my IP")
    const result = updateIpStatus(ipId, "inactive", "owner1")
    expect(result).toBe(true)
    const updatedIp = getIpDetails(ipId)
    expect(updatedIp.status).toBe("inactive")
  })
  
  it("should not allow unauthorized status update", () => {
    const ipId = registerIp("owner1", "My IP", "Description of my IP")
    expect(() => updateIpStatus(ipId, "inactive", "owner2")).toThrow("Unauthorized")
  })
  
  it("should correctly check IP ownership", () => {
    const ipId = registerIp("owner1", "My IP", "Description of my IP")
    expect(isIpOwner(ipId, "owner1")).toBe(true)
    expect(isIpOwner(ipId, "owner2")).toBe(false)
  })
})
