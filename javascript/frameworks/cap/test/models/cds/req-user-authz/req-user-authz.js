const cds = require("@sap/cds");

module.exports = class Service1 extends cds.ApplicationService {
  init() {
    /* ==================== Service.before  ==================== */

    /* ========== Authn/Authz on the entire Service. ========== */

    this.before("*", (req) => {
      req.user.is("authenticated") || req.reject(403);
    });

    this.before(
      "*",
      (req) => req.user.attr.Attribute1 == "expectedValue" || req.reject(403),
    );

    /*
     * Protect the whole service using `before`.
     * Translation of @(requires: [ "authenticated-user" ]).
     */
    this.before("*", (req) => {
      req.user.roles["Role1"] == 1 || // Exact match
        req.reject(403);
    });

    this.before("*", (req) => {
      !!req.user.roles["Role1"] || // Coerce to boolean
        req.reject(403);
    });

    this.before("*", (req) => {
      req.user.id == "expectedID" || // exact match
        req.reject(403);
    });

    this.before("*", (req) => {
      listOfIds.includes(req.user.id) || // membership
        req.reject(403);
    });

    this.before("*", (req) => {
      new Set(listOfIds).has(req.user.id) || // membership
        req.reject(403);
    });

    /* ========== Authn/Authz on the Entity. ========== */

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      req.user.is("authenticated") || req.reject(403);
    });

    this.before(
      ["WRITE", "UPDATE"],
      "Service1Entity",
      (req) => req.user.attr.Attribute1 == "expectedValue" || req.reject(403),
    );

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      req.user.roles["Role1"] == 1 || // Exact match
        req.reject(403);
    });

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      !!req.user.roles["Role1"] || // Coerce to boolean
        req.reject(403);
    });

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      req.user.id == "expectedID" || // exact match
        req.reject(403);
    });

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      listOfIds.includes(req.user.id) || // membership
        req.reject(403);
    });

    this.before(["WRITE", "UPDATE"], "Service1Entity", (req) => {
      new Set(listOfIds).has(req.user.id) || // membership
        req.reject(403);
    });

    /* ========== Authn/Authz on the Action. ========== */

    this.before("send1", (req) => {
      req.user.is("authenticated") || req.reject(403);
    });

    this.before(
      "send1",
      (req) => req.user.attr.Attribute1 == "expectedValue" || req.reject(403),
    );

    this.before("send1", (req) => {
      req.user.roles["Role1"] == 1 || // Exact match
        req.reject(403);
    });

    this.before("send1", (req) => {
      !!req.user.roles["Role1"] || // Coerce to boolean
        req.reject(403);
    });

    this.before("send1", (req) => {
      req.user.id == "expectedID" || // exact match
        req.reject(403);
    });

    this.before("send1", (req) => {
      listOfIds.includes(req.user.id) || // membership
        req.reject(403);
    });

    this.before("send1", (req) => {
      new Set(listOfIds).has(req.user.id) || // membership
        req.reject(403);
    });

    /* ========== Authn/Authz on the Function. ========== */

    this.before("fun1", (req) => {
      req.user.is("authenticated") || req.reject(403);
    });

    this.before(
      "fun1",
      (req) => req.user.attr.Attribute1 == "expectedValue" || req.reject(403),
    );

    this.before("fun1", (req) => {
      req.user.roles["Role1"] == 1 || // Exact match
        req.reject(403);
    });

    this.before("fun1", (req) => {
      !!req.user.roles["Role1"] || // Coerce to boolean
        req.reject(403);
    });

    this.before("fun1", (req) => {
      req.user.id == "expectedID" || // exact match
        req.reject(403);
    });

    this.before("fun1", (req) => {
      listOfIds.includes(req.user.id) || // membership
        req.reject(403);
    });

    this.before("fun1", (req) => {
      new Set(listOfIds).has(req.user.id) || // membership
        req.reject(403);
    });

    /* ========== Authn/Authz on the entire Service. ========== */

    this.on("*", (req) => {
      if (req.user.is("authenticated")) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (Service2Entity.Attribute3 == req.user.attr) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (
        req.user.roles["Role1"] == 1 // Exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (
        !!req.user.roles["Role1"] // Coerce to boolean
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (
        req.user.id == "expectedID" // exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (
        listOfIds.includes(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("*", (req) => {
      if (
        new Set(listOfIds).has(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    /* ========== Authn/Authz on the Entity. ========== */

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (req.user.is("Role2")) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (Service2Entity.Attribute3 == req.user.attr) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (
        req.user.roles["Role1"] == 1 // Exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (
        !!req.user.roles["Role1"] // Coerce to boolean
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (
        req.user.id == "expectedID" // exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (
        listOfIds.includes(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on(["WRITE", "UPDATE"], "Service2Entity", (req) => {
      if (
        new Set(listOfIds).has(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    /* ========== Authn/Authz on the Action. ========== */

    this.on("send2", (req) => {
      if (req.user.is("Role3")) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (Service1Entity.Attribute1 == req.user.attr.someAttribute) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (
        req.user.roles["Role1"] == 1 // Exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (
        !!req.user.roles["Role1"] // Coerce to boolean
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (
        req.user.id == "expectedID" // exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (
        listOfIds.includes(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("send2", (req) => {
      if (
        new Set(listOfIds).has(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    /* ========== Authn/Authz on the Function. ========== */

    this.on("fun2", (req) => {
      if (req.user.is("Role3")) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (Service1Entity.Attribute1 == req.user.attr.someAttribute) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (
        req.user.roles["Role1"] == 1 // Exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (
        !!req.user.roles["Role1"] // Coerce to boolean
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (
        req.user.id == "expectedID" // exact match
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (
        listOfIds.includes(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });

    this.on("fun2", (req) => {
      if (
        new Set(listOfIds).has(req.user.id) // membership
      ) {
        /* Do something */
      } else req.reject(403);
    });
  }
};
