/**
 * @license
 * Copyright (c) 2019 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
 */

import { PolymerElement, html } from '@polymer/polymer/polymer-element.js';
import '@polymer/iron-ajax/iron-ajax.js';
import '@polymer/paper-fab/paper-fab.js';
import '@polymer/iron-icons/iron-icons.js';
import '@vaadin/vaadin-grid/vaadin-grid.js';
import '@vaadin/vaadin-grid/vaadin-grid-filter.js';
import '@vaadin/vaadin-grid/vaadin-grid-sorter.js';
import '@vaadin/vaadin-grid/vaadin-grid-column-group.js';
import './style-element.js';

class inventoryList extends PolymerElement {
	static get template() {
		return html`
			<style include="style-element">
			</style>
			<vaadin-grid
					id="inventoryGrid"
					active-item="{{activeItem}}">
				<template class="row-details">
					<dl class="details">
						<dt><b>Inventory Details:</b></dt>
						<dd>{{item.inventoryDetails}}</dd>
					</dl>
				</template>
				<vaadin-grid-column width="11ex" flex-grow="2">
					<template class="header">
						<vaadin-grid-sorter
								path="id">
							<vaadin-grid-filter
									id="filterId"
									aria-label="Id"
									path="id"
									value="{{_filterId}}">
								<input
										slot="filter"
										placeholder="Id"
										value="{{_filterId::input}}"
										focus-target>
							</vaadin-grid-filter>
						</vaadin-grid-sorter>
					</template>
					<template>
						<div>
							[[item.id]]
						</div>
					</template>
				</vaadin-grid-column>
				<vaadin-grid-column width="11ex" flex-grow="2">
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
						<div>
							[[item.name]]
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
							[[item.Category]]
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
								path="inventoryType">
							<vaadin-grid-filter
									id="filterType"
									aria-label="Type"
									path="inventoryType"
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
							[[item.inventoryType]]
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
				id="getInventoryAjax"
				url="resourceInventoryManagement/v3/logicalResource"
				rejectWithRequest>
			</iron-ajax>
		`;
	}

	static get properties() {
		return {
			etag: {
				type: String,
				value: null
			},
			activeItem: {
				type: Boolean,
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
			var grid = this.shadowRoot.getElementById('inventoryGrid');
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
		var ajaxGrid = this.shadowRoot.getElementById('getInventoryAjax');
		grid.dataProvider = this._getInventoryList;
	}

	_getInventoryList(params, callback) {
		var grid = this;
		var inventoryList = document.body.querySelector('inventory-management').shadowRoot.querySelector('inventory-list').shadowRoot.getElementById('getInventoryAjax');
		if(inventoryList.etag && params.page > 0) {
			headers['If-Range'] = userList.etag;
		}
		var inventoryList1 = document.body.querySelector('inventory-management').shadowRoot.querySelector('inventory-list');
		var handleAjaxResponse = function(request) {
			if(request) {
				inventoryList1.etag = request.xhr.getResponseHeader('ETag');
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
					newRecord.id = request.response[index].id;
					newRecord.name = request.response[index].name;
					newRecord.category = request.response[index].category;
					newRecord.description = request.response[index].description;
					newRecord.type = request.response[index].inventoryType;
					vaadinItems[index] = newRecord;
				}
				callback(vaadinItems);
			} else {
				grid.size = 0;
				callback([]);
			}
		};
		var handleAjaxError = function(error) {
			alarmList1.etag = null;
			var toast;
			toast.text = "error";
			toast.open();
			if(!grid.size) {
				grid.size = 0;
			}
			callback([]);
		}
		if(inventoryList.loading) {
			inventoryList.lastRequest.completes.then(function(request) {
				var startRange = params.page * params.pageSize + 1;
				var endRange = startRange + params.pageSize - 1;
				inventoryList.headers['Range'] = "items=" + startRange + "-" + endRange;
				if (inventoryList1.etag && params.page > 0) {
					inventoryList.headers['If-Range'] = inventoryList1.etag;
				} else {
					delete inventoryList.headers['If-Range'];
				}
				return inventoryList.generateRequest().completes;
				}, handleAjaxError).then(handleAjaxResponse, handleAjaxError);
			} else {
				var startRange = params.page * params.pageSize + 1;
				var endRange = startRange + params.pageSize - 1;
				inventoryList.headers['Range'] = "items=" + startRange + "-" + endRange;
				if (inventoryList1.etag && params.page > 0) {
               inventoryList.headers['If-Range'] = inventoryList1.etag;
            } else {
               delete inventoryList.headers['If-Range'];
            }
				inventoryList.generateRequest().completes.then(handleAjaxResponse, handleAjaxError);
				}
			}
}

window.customElements.define('inventory-list', inventoryList);
