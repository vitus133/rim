/**
 * @license
 * Copyright (c) 2020 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
 */

import { PolymerElement, html } from '@polymer/polymer/polymer-element.js';
import {} from '@polymer/polymer/lib/elements/dom-if.js';
import {} from '@polymer/polymer/lib/elements/dom-repeat.js';
import { select } from 'd3-selection';
import { forceSimulation, forceManyBody, forceCenter, forceLink, forceY } from 'd3-force';
import '@polymer/iron-ajax/iron-ajax.js';
import '@polymer/paper-fab/paper-fab.js';
import '@vaadin/vaadin-grid/vaadin-grid.js';
import '@vaadin/vaadin-grid/vaadin-grid-filter.js';
import '@vaadin/vaadin-grid/vaadin-grid-sorter.js';
import './style-element.js';

class inventoryList extends PolymerElement {
	static get template() {
		return html`
			<style include="style-element"></style>
			<vaadin-grid
					id="inventoryGrid"
					loading="{{loading}}"
					active-item="{{activeItem}}">
				<template class="row-details">
					<dl class="details">
						<template is="dom-if" if="{{item.id}}">
							<dt><b>Id</b></dt>
							<dd>{{item.id}}</dd>
						</template>
						<template is="dom-if" if="{{item.href}}">
							<dt><b>Href</b></dt>
							<dd>{{item.href}}</dd>
						</template>
						<template is="dom-if" if="{{item.publicIdentifier}}">
							<dt><b>Public Id</b></dt>
							<dd>{{item.publicIdentifier}}</dd>
						</template>
						<template is="dom-if" if="{{item.name}}">
							<dt><b>Name</b></dt>
							<dd>{{item.name}}</dd>
						</template>
						<template is="dom-if" if="{{item.description}}">
							<dt><b>Description</b></dt>
							<dd>{{item.description}}</dd>
						</template>
						<template is="dom-if" if="{{item.category}}">
							<dt><b>Category</b></dt>
							<dd>{{item.category}}</dd>
						</template>
						<template is="dom-if" if="{{item.type}}">
							<dt><b>Class</b></dt>
							<dd>{{item.type}}</dd>
						</template>
						<template is="dom-if" if="{{item.type}}">
							<dt><b>Type</b></dt>
							<dd>{{item.type}}</dd>
						</template>
						<template is="dom-if" if="{{item.schema}}">
							<dt><b>Schema</b></dt>
							<dd>{{item.schema}}</dd>
						</template>
						<template is="dom-if" if="{{item.status}}">
							<dt><b>Status</b></dt>
							<dd>{{item.status}}</dd>
						</template>
						<template is="dom-if" if="{{item.version}}">
							<dt><b>Version</b></dt>
							<dd>{{item.version}}</dd>
						</template>
						<template is="dom-if" if="{{item.start}}">
							<dt><b>Start date</b></dt>
							<dd>{{item.start}}</dd>
						</template>
						<template is="dom-if" if="{{item.end}}">
							<dt><b>End date</b></dt>
							<dd>{{item.end}}</dd>
						</template>
						<template is="dom-if" if="{{item.lastModified}}">
							<dt><b>Last modified</b></dt>
							<dd>{{item.lastModified}}</dd>
						</template>
					</dl>
					<h3 class="inventoryDetail">Resource Characteristics:</h3>
					<dl class="details">
						<template is="dom-if" if="{{item.resourceChar}}">
							<template is="dom-repeat" items="{{item.resourceChar}}" as="detail">
								<template is="dom-if" if="{{detail.value}}">
									<dt>{{detail.name}}</dt>
									<dd>{{detail.value}}</dd>
								</template>
							</template>
						</template>
					</dl>
					<template is="dom-if" if="{{item.connectivity}}"
							on-dom-change="showInlineGraph">
						<h3 class="inventoryDetail">Connectivity:</h3>
						<svg id$="graph[[item.id]]" width="100%" />
					</template>
				</template>
				<vaadin-grid-column width="13ex" flex-grow="2">
					<template class="header">
						<vaadin-grid-sorter
								path="name">
							<vaadin-grid-filter
									id="filterName"
									aria-label="Name"
									path="name"
									value="{{_filterName}}">
								<input
										slot="filter"
										placeholder="Name"
										value="{{_filterName::input}}"
										focus-target>
							</vaadin-grid-filter>
						</vaadin-grid-sorter>
					</template>
					<template>
						<div class="timestamp">
							<bdo dir="ltr">[[item.name]]</bdo>
						</div>
					</template>
				</vaadin-grid-column>
				<vaadin-grid-column width="11ex" flex-grow="2">
					<template class="header">
						<vaadin-grid-sorter
								path="category">
							<vaadin-grid-filter
									id="filterCategory"
									aria-label="Category"
									path="category"
									value="{{_filterCategory}}">
								<input
										slot="filter"
										placeholder="Category"
										value="{{_filterCategory::input}}"
										focus-target>
							</vaadin-grid-filter>
						</vaadin-grid-sorter>
					</template>
					<template>
						<div>
							[[item.category]]
						</div>
					</template>
				</vaadin-grid-column>
				<vaadin-grid-column width="11ex" flex-grow="2">
					<template class="header">
						<vaadin-grid-sorter
								path="description">
							<vaadin-grid-filter
									id="filterDesc"
									aria-label="Description"
									path="description"
									value="{{_filterDescription}}">
								<input
										slot="filter"
										placeholder="Description"
										value="{{_filterDescription::input}}"
										focus-target>
							</vaadin-grid-filter>
						</vaadin-grid-sorter>
					</template>
					<template>
						<div>
							[[item.description]]
						</div>
					</template>
				</vaadin-grid-column>
				<vaadin-grid-column width="11ex" flex-grow="2">
					<template class="header">
						<vaadin-grid-sorter
								path="@type">
							<vaadin-grid-filter
									id="filterType"
									aria-label="Type"
									path="@type"
									value="{{_filterType}}">
								<input
										slot="filter"
										placeholder="Type"
										value="{{_filterType::input}}"
										focus-target>
							</vaadin-grid-filter>
						</vaadin-grid-sorter>
					</template>
					<template>
						<div>
							[[item.type]]
						</div>
					</template>
				</vaadin-grid-column>
			</vaadin-grid>
			<div class="add-button">
				<paper-fab
					icon="add"
					on-tap = "showAddInventoryModal">
				</paper-fab>
			</div>
			<iron-ajax
				id="inventoryGetAjax"
				url="resourceInventoryManagement/v4/resource"
				rejectWithRequest>
			</iron-ajax>
		`;
	}

	static get properties() {
		return {
			loading: {
				type: Boolean,
				notify: true
			},
			etag: {
				type: String,
				value: null
			},
			activeItem: {
				type: Boolean,
				notify: true,
				observer: '_activeItemChanged'
			},
			_filterId: {
				type: Boolean,
				observer: '_filterChanged'
			},
			_filterName: {
				type: Boolean,
				observer: '_filterChanged'
			},
			_filterCategory: {
				type: Boolean,
				observer: '_filterChanged'
			},
			_filterDescription: {
				type: Boolean,
				observer: '_filterChanged'
			},
			_filterType: {
				type: Boolean,
				observer: '_filterChanged'
			}
		}
	}

	_activeItemChanged(item, last) {
		if(item || last) {
			var grid = this.$.inventoryGrid;
			var current;
			if(item == null) {
				current = last;
			} else {
				current = item
			}
			function checkExist(inventory) {
				return inventory.id == current.id;
			}
			if(grid.detailsOpenedItems && grid.detailsOpenedItems.some(checkExist)) {
				grid.closeItemDetails(current);
			} else {
				grid.openItemDetails(current);
			}
		}
	}

	ready() {
		super.ready();
		var grid = this.shadowRoot.getElementById('inventoryGrid');
		grid.dataProvider = this._getInventory;
	}

	_getInventory(params, callback) {
		var grid = this;
		if(!grid.size) {
				grid.size = 0;
		}
		var inventoryList = document.body.querySelector('inventory-management').shadowRoot.querySelector('inventory-list');
		var ajax = inventoryList.shadowRoot.getElementById('inventoryGetAjax');
		delete ajax.params['filter'];
		var query = "";
		params.filters.forEach(function(filter) {
			if(filter.value) {
				if(filter.value.includes("=")) {
					var sourceReplace = filter.value.replace(/=/g, "\\=").replace(/,/g, "\\,");
					if(query) {
						query = query + "," + filter.path + ".like=[" + sourceReplace + "%]";
					} else {
						query = "[{" + filter.path + ".like=[" + sourceReplace + "%]";
					}
				} else if(query) {
					query = query + "," + filter.path + ".like=[" + filter.value + "%]";
				} else {
					query = "[{" + filter.path + ".like=[" + filter.value + "%]";
				}
			}
		});
		if(query) {
			if(query.includes("like=[%")) {
				delete params.filters[0];
				ajax.params['filter'] = "resourceInventoryManagement/v4/resource";
			} else {
				ajax.params['filter'] = "\"" + query + "}]\"";
			}
		}
		if(inventoryList.etag && params.page > 0) {
			ajax.headers['If-Range'] = inventoryList.etag;
		}
		var handleAjaxResponse = function(request) {
			if(request) {
				inventoryList.etag = request.xhr.getResponseHeader('ETag');
				var range = request.xhr.getResponseHeader('Content-Range');
				var range1 = range.split("/");
				var range2 = range1[0].split("-");
				if (range1[1] != "*") {
					grid.size = Number(range1[1]);
				} else {
					grid.size = Number(range2[1]) + grid.pageSize * 2;
				}
				var vaadinItems = new Array();
				for(var index in request.response) {
					var newRecord = new Object();
					if(request.response[index].id) {
						newRecord.id = request.response[index].id;
					}
					if(request.response[index].href) {
						newRecord.href = request.response[index].href;
					}
					if(request.response[index].publicIdentifier) {
						newRecord.publicIdentifier = request.response[index].publicIdentifier;
					}
					if(request.response[index].name) {
						newRecord.name = request.response[index].name;
					}
					if(request.response[index].description) {
						newRecord.description = request.response[index].description;
					}
					if(request.response[index].category) {
						newRecord.category = request.response[index].category;
					}
					if(request.response[index]["@type"]) {
						newRecord.type = request.response[index]["@type"];
					}
					if(request.response[index]["@baseType"]) {
						newRecord.base = request.response[index]["@baseType"];
					}
					if(request.response[index]["@schemaLocation"]) {
						newRecord.schema = request.response[index]["@schemaLocation"];
					}
					if(request.response[index].lifecycleStatus) {
						newRecord.status = request.response[index].lifecycleStatus;
					}
					if(request.response[index].lifecycleSubStatus) {
						newRecord.substatus = request.response[index].lifecycleSubStatus;
					}
					if(request.response[index].version) {
						newRecord.version = request.response[index].version;
					}
					if(request.response[index].startDateTime) {
						newRecord.start = request.response[index].startDateTime;
					}
					if(request.response[index].endDateTime) {
						newRecord.end = request.response[index].endDateTime;
					}
					if(request.response[index].lastUpdate) {
						newRecord.lastModified = request.response[index].lastUpdate;
					}
					if(request.response[index].connectivity) {
						newRecord.connectivity = request.response[index].connectivity;
					}
					var resChar = request.response[index].resourceCharacteristic;
					for(var index1 in resChar) {
						if(resChar[index1].value != []) {
							var ValueArray = new Array();
							ValueArray.push(resChar[index1].value);
							for(var str in ValueArray) {
								var str1 = JSON.stringify(ValueArray[str]);
								var str2 = str1.trim();
								var res = str2.replace(/"|{|[|[|}|]|]/g, " ");
								resChar[index1].value = res;
								newRecord.resourceChar = resChar;
							}
						} else {
							newRecord.resourceChar = resChar;
						}
					}
					vaadinItems[index] = newRecord;
				}
				callback(vaadinItems);
			} else {
				callback([]);
			}
		};
		var handleAjaxError = function(error) {
			inventoryList.etag = null;
			var toast = document.body.querySelector('inventory-management').shadowRoot.getElementById('restError');
			toast.text = error;
			toast.open();
			callback([]);
		}
		if(ajax.loading) {
			ajax.lastRequest.completes.then(function(request) {
				var startRange = params.page * params.pageSize + 1;
				var endRange = startRange + params.pageSize - 1;
				ajax.headers['Range'] = "items=" + startRange + "-" + endRange;
				if (inventoryList.etag && params.page > 0) {
					ajax.headers['If-Range'] = inventoryList.etag;
				} else {
					delete ajax.headers['If-Range'];
				}
				return ajax.generateRequest().completes;
			}, handleAjaxError).then(handleAjaxResponse, handleAjaxError);
		} else {
			var startRange = params.page * params.pageSize + 1;
			var endRange = startRange + params.pageSize - 1;
			ajax.headers['Range'] = "items=" + startRange + "-" + endRange;
			if (inventoryList.etag && params.page > 0) {
				ajax.headers['If-Range'] = inventoryList.etag;
			} else {
				delete ajax.headers['If-Range'];
			}
			ajax.generateRequest().completes.then(handleAjaxResponse, handleAjaxError);
		}
	}

	_filterChanged(filter) {
		this.etag = null;
		var grid = this.shadowRoot.getElementById('inventoryGrid');
		grid.size = 0;
	}

	showAddInventoryModal(event) {
		document.body.querySelector('inventory-management').shadowRoot.querySelector('inventory-add').shadowRoot.getElementById('inventoryAddModal').open();
	}

	showInlineGraph(event) {
		var grid = this.$.inventoryGrid;
		var connectivity = event.model.item.connectivity;
		if (connectivity.length > 0) {
			var gridGraph = grid.querySelector('#graph' + event.model.item.id);
			var width = gridGraph.clientWidth;
			var height = gridGraph.clientHeight;
			// var height = Math.ceil(gridGraph.clientWidth * 0.5625);
			// gridGraph.style.height = height + 'px';
			var graph = select(this.$.inventoryGrid)
					.select('#graph' + event.model.item.id);
			_connectivityGraph(connectivity.shift().connection, graph, width, height);
		}
	}
}

function _connectivityGraph(connections, graph, width, height) {
	var vertices = [];
	function mapEdge(connection) {
		let edge = {};
		if(connection.id) {
			edge.id = connection.id;
		}
		if(connection.name) {
			edge.name = connection.name;
		}
		if(connection.associationType) {
			edge.associationType = connection.associationType;
		}
		if(connection.endpoint) {
			let index = vertices.findIndex(function (vertex) {
				return vertex.id == connection.endpoint[0].id;
			});
			if(index == -1) {
				let v0 = {};
				v0.id = connection.endpoint[0].id;
				if(connection.endpoint[0].name) {
					v0.name = connection.endpoint[0].name;
				}
				if(connection.endpoint[0]["@referredType"]) {
					v0.type = connection.endpoint[0]["@referredType"];
				}
				edge.source = vertices.push(v0) - 1;
			} else {
				edge.source = index;
			}
			index = vertices.findIndex(function (vertex) {
				return vertex.id == connection.endpoint[1].id;
			});
			if(index == -1) {
				let v1 = {};
				v1.id = connection.endpoint[1].id;
				if(connection.endpoint[1].name) {
					v1.name = connection.endpoint[1].name;
				}
				if(connection.endpoint[1]["@referredType"]) {
					v1.type = connection.endpoint[1]["@referredType"];
				}
				edge.target = vertices.push(v1) - 1;
			} else {
				edge.target = index;
			}
		}
		return edge;
	}
	var edges = connections.map(mapEdge);
	var simulation = forceSimulation(vertices)
			.force("center", forceCenter(Math.ceil(width/2), Math.ceil(height/2)))
			.force("charge", forceManyBody().strength(-800))
			.force("link", forceLink(edges).distance(100))
			.force('y', forceY());
	var edge = graph.selectAll('.edge')
			.data(edges)
			.enter()
			.append('line')
					.attr('class', 'edge');
	var vertex = graph.selectAll('g.vertex')
			.data(vertices);
	var vgroup = vertex.enter()
			.append('g')
	var circle = vgroup.append('circle')
			.attr('r', Math.ceil(width / 100))
			.attr('class', 'vertex')
			.append('title')
			.text(function(d) { return d.name});
	vgroup.append('text')
			.text(function(d) { return d.type })
			.attr('y', - Math.ceil(width / 100) - 8 )
			.attr('text-anchor', 'middle');
	simulation.on('tick', function() {
		vgroup.attr('transform', function(d) {
				return 'translate(' + Math.ceil(d.x) + ',' + Math.ceil(d.y) + ')';
		});
		edge.attr('x1', function(d) { return Math.ceil(d.source.x) })
				.attr('y1', function(d) { return Math.ceil(d.source.y) })
				.attr('x2', function(d) { return Math.ceil(d.target.x) })
				.attr('y2', function(d) { return Math.ceil(d.target.y) });
	});
}

window.customElements.define('inventory-list', inventoryList);
