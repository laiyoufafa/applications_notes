/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import DateUtil from '@ohos/utils/src/main/ets/default/baseUtil/DateUtil'
import FolderData from '@ohos/utils/src/main/ets/default/model/databaseModel/FolderData'
import NoteData from '@ohos/utils/src/main/ets/default/model/databaseModel/NoteData'
import { TableName, NoteTableColumn, SysDefFolderUuid, Favorite, Delete, Top, NoteType
} from '@ohos/utils/src/main/ets/default/model/databaseModel/EnumData'
import { NoteDataMoveDialog, DeleteDialog } from './CusDialogComp'
import RdbStoreUtil from '@ohos/utils/src/main/ets/default/baseUtil/RdbStoreUtil'
import prompt from '@system.prompt'
import NoteUtil from '@ohos/utils/src/main/ets/default/baseUtil/NoteUtil'
import FolderUtil from '@ohos/utils/src/main/ets/default/baseUtil/FolderUtil'
import StyleConstants from '@ohos/utils/src/main/ets/default/constants/StyleConstants'
import SearchModel from '@ohos/utils/src/main/ets/default/model/searchModel/SearchModel'
import { LogUtil } from '@ohos/utils/src/main/ets/default/baseUtil/LogUtil'
import router from '@system.router';

const TAG = "NoteListComp"

async function routePage() {
  let options = {
    uri: 'pages/NoteContentHome'
  }
  try {
    await router.push(options)
  } catch (err) {
    LogUtil.info(TAG, "fail callback")
  }
}

// Note list component
@Component
export struct NoteListComp {
  @StorageLink('AllFolderArray') AllFolderArray: FolderData[]  = AppStorage.Link('AllFolderArray')
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('Search') search: boolean
  controllerShow: WebController

  build() {
    Flex({ direction: FlexDirection.Column }) {

      Flex({ direction: FlexDirection.Column }) {
        NoteOverViewComp({ controllerShow: this.controllerShow })
        Column() {
        }
        .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
        .height(this.search ? 15 : 0)

        NoteItemListComp({ controllerShow: this.controllerShow })
      }
      .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
      .width('100%')
      .flexGrow(1)

      Column() {
        OperateNoteCompForPortrait()
      }
      .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
    }
    .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
    .height('100%')
    .width('100%')
  }

  aboutToAppear(): void{
    LogUtil.info(TAG, "aboutToAppear")
  }

  aboutToDisappear(): void{
    LogUtil.info(TAG, "aboutToDisappear")
  }
}

@Component
struct NoteOverViewComp {
  @StorageLink('AllNoteArray') AllNoteArray: NoteData[]  = AppStorage.Link('AllNoteArray')
  @StorageLink('CheckedNoteArray') CheckedNoteArray: NoteData[]  = []
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('RefreshFlag') refreshFlag: number
  @Consume('SectionStatus') sectionStatus: number
  @Consume("Longpress") longpress: boolean
  @Consume('ExpandStatus') expandStatus: boolean
  @Consume('Search') search: boolean
  controllerShow: WebController

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Column() {
          Image($r("app.media.suojin_back"))
            .height(24)
            .width(24)
            .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
            .margin({ right: this.sectionStatus != 3 ? 24 : 0 }) // 两分栏时缩进图片与右边有个24的间距
            .visibility(this.sectionStatus != 3 ? Visibility.Visible : Visibility.None)
            .onClick(() => {
              if (this.sectionStatus == 1) {
                this.expandStatus = !this.expandStatus
              } else {
                this.sectionStatus = (this.sectionStatus == 3 ? 2 : 3)
                // save continue data
                AppStorage.SetOrCreate<number>('ContinueSection', this.sectionStatus)
                LogUtil.info(TAG, "NoteOverViewComp, set continue section success")
              }
            })
        }.alignItems(HorizontalAlign.Center)

        Flex({
          direction: FlexDirection.Column,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Start
        }) {
          Text(FolderUtil.getFolderText(this.selectedFolderData))
            .fontSize(30)
            .fontColor($r("app.color.all_notes_font_color"))
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(FolderUtil.getNoteCount(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid).toString())
              .fontSize(14)
              .fontColor($r("app.color.num_of_notes_font_color"))
            Text($r("app.string.noteslist"))
              .fontSize(14)
              .fontColor($r("app.color.num_of_notes_font_color"))
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .visibility((FolderUtil.getNoteCount(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid) == 0) ? Visibility.None : Visibility.Visible)
        }.visibility(this.longpress ? Visibility.None : Visibility.Visible)

        Row() {
          Image($r("app.media.cross"))
            .height(24)
            .width(24)
            .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
            .onClick(() => {
              this.longpress = false
              this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
              NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
            })
          Text(this.CheckedNoteArray.length == 0 ? $r("app.string.none_selected") : $r("app.string.selected", this.CheckedNoteArray.length))
            .fontSize(20)
            .fontColor($r("app.color.note_selected_font_color"))
            .margin({ left: 16 })
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }.alignItems(VerticalAlign.Center)
        .visibility(this.longpress ? Visibility.Visible : Visibility.None)
      }.padding({ top: 8, bottom: 8 })
      .height('100%')

      AddNoteComp({ controllerShow: this.controllerShow })
      OperateNoteComp({ controllerShow: this.controllerShow })
      Text(this.refreshFlag.toString()).visibility(Visibility.None)
    }
    .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
    .width('100%')
    .height(82)
    .padding({ left: this.sectionStatus == 2 ? 24 : 36, right: 24 }) // 两分栏时缩进图标与左侧不需要间距
    .visibility(this.search ? Visibility.None : Visibility.Visible)
  }
}

@Component
export struct NoteItemComp {
  public noteItem: NoteData
  public spans: any[]
  controllerShow: WebController
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('SelectedNoteData') selectedNoteData: NoteData
  @StorageLink('AllFolderArray') AllFolderArray: FolderData[]  = AppStorage.Link('AllFolderArray')
  @StorageLink('CheckedNoteArray') CheckedNoteArray: NoteData[]  = []
  @Consume('Longpress') longpress: boolean
  @Consume('ChooseNote') chooseNote: boolean
  @Consume('RefreshFlag') refreshFlag: number
  @Consume('Search') search: boolean
  @Consume('selectedAll') selectedAll: boolean
  @Consume('PortraitModel') portraitModel: boolean

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Text(this.refreshFlag.toString()).visibility(Visibility.None) // 用于强制刷新使用
        Column({ space: 2 }) {
          Row({ space: 8 }) {
            Image($r("app.media.verticalBar"))
              .height(16)
              .width(4)
              .fillColor(NoteUtil.getVerticalBarBgColor(AppStorage.Get('AllFolderArray'), this.noteItem.folder_uuid))
            Text() {
              ForEach(this.spans.map((item1, index1) => {
                return { index: index1, data: item1 }
              }), item => {

                if (item.data.type == 0) {
                  Span(item.data.text)
                    .fontColor($r("app.color.note_title_font_color"))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                } else if (item.data.type == 1) {
                  Span(item.data.text)
                    .fontColor($r("app.color.note_title_font_color_blue"))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                }
              },
                item => item.index)
            }.textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Row({ space: 4 }) {
            Text(DateUtil.formateDateForNoteTitle(new Date(this.noteItem.modified_time)))
              .fontSize(14)
              .fontColor($r("app.color.list_modified_time_font_color"))
              .fontWeight(FontWeight.Regular)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Image($r("app.media.favorite"))
              .height(16)
              .width(16)
              .visibility(this.noteItem.is_favorite == Favorite.Yes ? Visibility.Visible : Visibility.None)
            Image($r("app.media.topped"))
              .height(16)
              .width(16)
              .visibility(this.noteItem.is_top == Top.Yes ? Visibility.Visible : Visibility.None)
          }
          .padding({ left: 12 })
        }.alignItems(HorizontalAlign.Start)
      }.flexShrink(1)

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          Image(this.noteItem.content_img)
            .height(47)
            .width(47)
            .borderRadius(12)
            .border({ width: 0.5, color: '#19182431' })
            .visibility(this.noteItem.content_img ? Visibility.Visible : Visibility.None)
        }

        Stack({ alignContent: Alignment.Center }) {
          Image($r("app.media.unChecked"))
            .height(24)
            .width(24)
          Image($r("app.media.checked"))
            .width(24)
            .height(24)
            .visibility(NoteUtil.isNoteChecked(this.CheckedNoteArray, this.noteItem) ? Visibility.Visible : Visibility.None)
        }.width(24)
        .height(24)
        .visibility(this.longpress ? Visibility.Visible : Visibility.None)
      }
      .flexShrink(0)
      .height(48)
      .width(this.longpress ? 80 : 48)
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 12, top: 4, bottom: 4 })
    .borderRadius(24)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: this.selectedNoteData.uuid == this.noteItem.uuid ? [[0xffcdae, 0.0], [0xFfece2, 1.0]] : [[0xffffff, 0.0], [0xffffff, 1.0]]
    })
    .onClick(() => {
      if (this.search) {
        this.search = false
        return
      }
      if (this.longpress) {
        if (NoteUtil.isNoteChecked(this.CheckedNoteArray, this.noteItem)) {
          NoteUtil.unsetNoteChecked(this.CheckedNoteArray, this.noteItem)
          this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
        } else {
          NoteUtil.setNoteChecked(this.CheckedNoteArray, this.noteItem)
          this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
        }
        return;
      } else {
        this.selectedNoteData = this.noteItem
        this.chooseNote = true
        // save continue data
        let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
        AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
        LogUtil.info(TAG, "NoteItemComp, set continue note success")
      }
      if (this.portraitModel == false) {
        this.controllerShow.runJavaScript({
          script: "RICH_EDITOR.setHtml('" + this.selectedNoteData.content_text + "')"
        })
      }
      if (this.portraitModel == true) {
        AppStorage.SetOrCreate<NoteData>('NewNote', this.selectedNoteData)
        AppStorage.SetOrCreate<FolderData>('NewFolder', this.selectedFolderData)
        routePage()
      }
      this.selectedAll = this.CheckedNoteArray.length ==
      NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid).length
      this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
    })
    .gesture(
    GestureGroup(GestureMode.Exclusive,
      // 长按：对笔记列表进行操作
    LongPressGesture()
      .onAction(() => {
        if (this.longpress == false) {
          this.longpress = true
          NoteUtil.setNoteChecked(this.CheckedNoteArray, this.noteItem)
        }
      })
    )
    )

  }
}

@Component
export struct NoteItemListComp {
  @StorageLink('AllNoteArray') AllNoteArray: NoteData[]  = AppStorage.Link('AllNoteArray')
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('RefreshFlag') refreshFlag: number
  @Consume('Longpress') longpress: boolean
  @Consume('Search') search: boolean
  @Consume @Watch('doSearch') inputKeyword: string
  @Consume('SearchResultList') searchResultList: NoteData[]
  @Consume('SelectedNoteData') selectedNoteData: NoteData
  @Consume('PortraitModel') portraitModel: boolean
  controllerShow: WebController

  doSearch() {
    SearchModel.search(NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid), this.inputKeyword)
      .then((result: NoteData[]) => {
        LogUtil.info(TAG, "result size " + result.length.toString())
        this.searchResultList = result
        if (this.searchResultList.length != 0) {
          this.selectedNoteData = this.searchResultList[0]
        } else {
          this.selectedNoteData = NoteUtil.getFirstNoteData(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid)
        }
        if (this.portraitModel == false) {
          this.controllerShow.runJavaScript({
            script: "RICH_EDITOR.setHtml('" + this.selectedNoteData.content_text + "')"
          })
        }
        // save continue data
        let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
        AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
        LogUtil.info(TAG, "doSearch, set continue note success")
        this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
      })
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Text(this.refreshFlag.toString()).visibility(Visibility.None)
      Flex() {
        SearchComp()
      }
      .width("100%")
      .padding({ left: 24, right: 24, bottom: 12 })
      .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
      .visibility((FolderUtil.getNoteCount(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid) == 0) ? Visibility.None : Visibility.Visible)

      Stack() {
        Flex({ justifyContent: FlexAlign.Center }) {
          Text($r("app.string.permanently_delete_tips"))
            .fontSize(12)
            .fontColor($r("app.color.Recently_delete_prompt_font_color"))
        }
        .padding({ bottom: this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? 12 : 0 })
        .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
        .width('100%')
        .visibility(this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? Visibility.Visible : Visibility.None)

        Column() {
          List({ initialIndex: 0 }) {
            ListItem() {
              Column({ space: 8 }) {
                Image($r('app.media.emptyPage'))
                  .width(120)
                  .height(120)
                Text($r("app.string.Empty_page"))
                  .fontSize(12)
                  .fontColor($r("app.color.Empty_page_font_color"))
              }
            }
            .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
            .width('100%')
            .height('100%')
            .padding({ bottom: 120 })
            .visibility((FolderUtil.getNoteCount(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid) == 0) ? Visibility.Visible : Visibility.None)

            ForEach(this.inputKeyword.length == 0 ?
            NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid) : this.searchResultList, (noteItem) => {
              ListItem() {
                Column() {
                  NoteItemComp({
                    noteItem: noteItem,
                    spans: SearchModel.splitToHighlightText(noteItem.title, this.inputKeyword),
                    controllerShow: this.controllerShow
                  })
                }
                .padding({ left: 24, right: 24, bottom: 12 })
              }
              .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
            }, noteItem => noteItem.uuid.toString())
          }
          .height("100%")
          .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
          .listDirection(Axis.Vertical)
          .edgeEffect(EdgeEffect.Spring)
        }
        .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
        .flexGrow(1)
        .margin({ top: this.search ? 8 : 0 })

        Column() {
        }
        .height("100%")
        .width("100%")
        .backgroundColor("#18181A")
        .opacity(0.1)
        .visibility(this.search ? Visibility.Visible : Visibility.Hidden)
      }
      .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
      .flexGrow(1)
    }
    .backgroundColor($r("app.color.notelist_bgcolor_f1f3f5"))
    .flexGrow(1)
    .onClick(() => {
      this.search = false
    })
  }
}

@Component
export struct OperateNoteComp {
  @Consume('Longpress') longpress: boolean
  @StorageLink('CheckedNoteArray') CheckedNoteArray: NoteData[]  = []
  @StorageLink('AllNoteArray') AllNoteArray: NoteData[]  = AppStorage.Link('AllNoteArray')
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('RefreshFlag') refreshFlag: number
  @Consume('SelectedNoteData') selectedNoteData: NoteData
  @Consume('PortraitModel') portraitModel: boolean
  @Consume('selectedAll') selectedAll: boolean
  controllerShow: WebController
  noteDataMoveDialogCtl: CustomDialogController = new CustomDialogController({
    builder: NoteDataMoveDialog({ onConfirm: this.onMoveConfirm.bind(this) }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    customStyle: true,
  })

  onMoveConfirm(folderUuid: string) {
    this.CheckedNoteArray.forEach((noteItem) => {
      noteItem.folder_uuid = folderUuid
      // update note to db
      let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
      predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
      RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
    })
    this.selectedNoteData = NoteUtil.getFirstNoteData(this.AllNoteArray, this.selectedFolderData.uuid)
    // save continue data
    let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
    AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
    LogUtil.info(TAG, "onMoveConfirm, set continue note success")
    if (this.portraitModel == false) {
      this.controllerShow.runJavaScript({ script: "RICH_EDITOR.setHtml('" + this.selectedNoteData.content_text + "')" })
    }
    this.longpress = false
    this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
    NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
  }

  noteDataDeleteDialogCtl: CustomDialogController = new CustomDialogController({
    builder: DeleteDialog({ onConfirm: this.onDeleteConfirm.bind(this), multiSelect: true }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    customStyle: true,
  })

  onDeleteConfirm() {
    if (this.selectedFolderData.uuid != SysDefFolderUuid.RecentDeletes) {
      this.CheckedNoteArray.forEach((noteItem: NoteData) => {
        noteItem.is_deleted = Delete.Yes
        noteItem.deleted_time = new Date().getTime()
        // update note to db
        let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
        predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
        RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
      })
    } else {
      this.CheckedNoteArray.forEach((noteItem: NoteData) => {
        NoteUtil.removeNoteData(this.AllNoteArray, noteItem.uuid)
        // delete note from db
        let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
        predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
        RdbStoreUtil.delete(predicates_note, null)
      })
    }
    NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
    this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
    this.longpress = false
    this.selectedNoteData = NoteUtil.getFirstNoteData(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid)
    if (this.portraitModel == false) {
      this.controllerShow.runJavaScript({ script: "RICH_EDITOR.setHtml('" + this.selectedNoteData.content_text + "')" })
    }
    // save continue data
    let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
    AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
    LogUtil.info(TAG, "OperateNoteComp, set continue note success")
  }

  build() {
    Row() {
      Image($r('app.media.set_top'))
        .width(24)
        .height(24)
        .opacity(this.CheckedNoteArray.length == 0 ? 0.4 : 1)
        .enabled(this.CheckedNoteArray.length == 0 ? false : true)
        .margin({ right: this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? 0 : 24 })
        .visibility(this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? Visibility.None : Visibility.Visible)
        .onClick(() => {
          this.CheckedNoteArray.forEach((noteItem) => {
            noteItem.is_top = (noteItem.is_top == Top.Yes) ? Top.No : Top.Yes
            // update note to db
            let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
            predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
            RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
          })
          this.longpress = false
          NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
        })
      Image($r('app.media.move'))
        .width(24)
        .height(24)
        .opacity(this.CheckedNoteArray.length == 0 ? 0.4 : 1)
        .enabled(this.CheckedNoteArray.length == 0 ? false : true)
        .margin({ right: this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? 0 : 24 })
        .visibility(this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? Visibility.None : Visibility.Visible)
        .onClick(() => {
          this.noteDataMoveDialogCtl.open()
        })
      Image($r('app.media.delete'))
        .width(24)
        .height(24)
        .margin({ right: 24 })
        .opacity(this.CheckedNoteArray.length == 0 ? 0.4 : 1)
        .enabled(this.CheckedNoteArray.length == 0 ? false : true)
        .onClick(() => {
          this.noteDataDeleteDialogCtl.open()
        })
      Image($r('app.media.recover'))
        .width(24)
        .height(24)
        .opacity(this.CheckedNoteArray.length == 0 ? 0.4 : 1)
        .enabled(this.CheckedNoteArray.length == 0 ? false : true)
        .margin({ right: this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? 24 : 0 })
        .visibility(this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.CheckedNoteArray.forEach((noteItem) => {
            noteItem.is_deleted = Delete.No
            noteItem.deleted_time = 0
            prompt.showToast({ message: $r('app.string.restore').toString(), duration: 2000 })
            // update note to db
            let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
            predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
            RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
          })
          this.longpress = false
          NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
        })
      Image(this.selectedAll ? $r('app.media.check_all1') : $r('app.media.check_all'))
        .width(24)
        .height(24)
        .onClick(() => {
          if (this.CheckedNoteArray.length <
          NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid)
          .length) {
            NoteUtil.setAllNotesChecked(this.CheckedNoteArray, NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid))
          } else {
            NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
          }
          this.selectedAll = !this.selectedAll
          this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
        })
    }
    .width(this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? 120 : 168)
    .visibility(this.longpress && this.portraitModel == false ? Visibility.Visible : Visibility.None)
  }
}

@Component
export struct AddNoteComp {
  @StorageLink('AllNoteArray') AllNoteArray: NoteData[]  = AppStorage.Link('AllNoteArray')
  @Consume('Longpress') longpress: boolean
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('SelectedNoteData') selectedNoteData: NoteData
  @Consume('SectionStatus') sectionStatus: number
  @Consume('LastSectionStatus') lastSectionStatus: number
  @Consume('EditModel') editModel: boolean
  @Consume('ChooseNote') chooseNote: boolean
  @Consume('PortraitModel') portraitModel: boolean
  controllerShow: WebController

  build() {
    Image($r('app.media.addNote'))
      .width(24)
      .height(24)
      .margin({ right: 12 })
      .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
      .onClick(() => {
        let noteData
        if (this.selectedFolderData.uuid == SysDefFolderUuid.AllNotes) {
          noteData = new NoteData(0, "标题", new Date().getTime() + "", SysDefFolderUuid.UnClassified, "", "", NoteType.SysDef, Top.No, Favorite.No, Delete.No, new Date().getTime(), new Date().getTime(), 0)
        } else {
          noteData = new NoteData(0, "标题", new Date().getTime() + "", this.selectedFolderData.uuid, "", "", NoteType.SysDef, Top.No, Favorite.No, Delete.No, new Date().getTime(), new Date().getTime(), 0)
        }

        this.AllNoteArray.push(noteData)
        RdbStoreUtil.insert(TableName.NoteTable, noteData.toNoteObject(), null)
        LogUtil.info(TAG, 'insert new note is:' + noteData.uuid)

        this.selectedNoteData = noteData
        AppStorage.SetOrCreate<NoteData>('NewNote', noteData)
        if (this.portraitModel == false) {
          this.controllerShow.runJavaScript({
            script: "RICH_EDITOR.setHtml('" + this.selectedNoteData.content_text + "')"
          })
        }
        if (this.portraitModel == true) {
          this.editModel = true
        }
        this.chooseNote = true
        // save continue data
        let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
        AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
        LogUtil.info(TAG, "addNote, set continue note success")
        routePage()
      })
      .visibility(this.longpress || this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes ? Visibility.None : Visibility.Visible)
  }
}

@Component
export struct SearchComp {
  @Consume('Search') search: boolean
  @Consume('InputKeyword') inputKeyword: string

  build() {
    Row() {
      Image($r('app.media.back'))
        .width(24)
        .height(24)
        .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
        .margin({ right: this.search ? 16 : 0 })
        .visibility(this.search ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.search = false
        })

      Flex({ justifyContent: FlexAlign.Start }) {
        Image($r('app.media.search')).width(18).height(18)
        TextInput({ placeholder: $r('app.string.searchNote') })
          .backgroundColor($r("app.color.color_ffffff"))
          .caretColor($r("app.color.search_note_caret_color"))
          .onChange((value: string) => {
            LogUtil.info(TAG, "Search value: " + value)
            this.inputKeyword = value
          })
          .onEditChange((isEditing: boolean) => {
            this.search = isEditing
          })
      }
      .height(40)
      .padding({ left: 6, right: 12, top: 9, bottom: 9 })
      .borderRadius(20)
      .backgroundColor($r("app.color.color_ffffff"))
      .border({ width: 1.5, color: $r("app.color.divider_color_e4e4e4") })
      .margin({ right: this.search ? 40 : 0 })
    }
    .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
  }
}

@Component
export struct OperateNoteCompForPortrait {
  @Consume('Longpress') longpress: boolean
  @StorageLink('CheckedNoteArray') CheckedNoteArray: NoteData[]  = []
  @StorageLink('AllNoteArray') AllNoteArray: NoteData[]  = AppStorage.Link('AllNoteArray')
  @Consume('SelectedFolderData') selectedFolderData: FolderData
  @Consume('RefreshFlag') @Watch('opacityChange') refreshFlag: number
  @Consume('SelectedNoteData') selectedNoteData: NoteData
  @Consume('PortraitModel') portraitModel: boolean
  @State greyOpacity: boolean = false
  noteDataMoveDialogCtlBottom: CustomDialogController = new CustomDialogController({
    builder: NoteDataMoveDialog({ onConfirm: this.onMoveConfirm.bind(this) }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    customStyle: true,
  })

  opacityChange() {
    if (this.CheckedNoteArray.length == 0) {
      this.greyOpacity = true
      LogUtil.info(TAG, "none checked array")
    } else {
      this.greyOpacity = false
      LogUtil.info(TAG, this.CheckedNoteArray.length.toString())
    }
  }

  onMoveConfirm(folderUuid: string) {
    this.CheckedNoteArray.forEach((noteItem) => {
      noteItem.folder_uuid = folderUuid
      // update note to db
      let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
      predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
      RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
    })
    this.selectedNoteData = NoteUtil.getFirstNoteData(this.AllNoteArray, this.selectedFolderData.uuid)
    // save continue data
    let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
    AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
    LogUtil.info(TAG, "onMoveConfirm, set continue note success")
    this.longpress = false
    this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
    NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
  }

  noteDataDeleteDialogCtlBottom: CustomDialogController = new CustomDialogController({
    builder: DeleteDialog({ onConfirm: this.onDeleteConfirm.bind(this), multiSelect: true }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    customStyle: true,
  })

  onDeleteConfirm() {
    if (this.selectedFolderData.uuid != SysDefFolderUuid.RecentDeletes) {
      this.CheckedNoteArray.forEach((noteItem: NoteData) => {
        noteItem.is_deleted = Delete.Yes
        noteItem.deleted_time = new Date().getTime()
        // update note to db
        let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
        predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
        RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
      })
    } else {
      this.CheckedNoteArray.forEach((noteItem: NoteData) => {
        NoteUtil.removeNoteData(this.AllNoteArray, noteItem.uuid)
        // delete note from db
        let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
        predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
        RdbStoreUtil.delete(predicates_note, null)
      })
    }
    NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
    this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
    this.longpress = false
    this.selectedNoteData = NoteUtil.getFirstNoteData(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid)
    // save continue data
    let continueNote: string = JSON.stringify(this.selectedNoteData.toNoteObject())
    AppStorage.SetOrCreate<string>('ContinueNote', continueNote)
    LogUtil.info(TAG, "OperateNoteCompForPortrait, set continue note success")
  }

  build() {
    Row() {
      if (this.selectedFolderData.uuid != SysDefFolderUuid.RecentDeletes) {
        Column() {
          Image($r("app.media.set_top"))
            .opacity(this.greyOpacity ? 0.4 : 1)
            .width(24)
            .height(24)
            .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
            .onClick(() => {
              this.CheckedNoteArray.forEach((noteItem) => {
                noteItem.is_top = (noteItem.is_top == Top.Yes) ? Top.No : Top.Yes
                // update note to db
                let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
                predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
                RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
              })
              this.longpress = false
              NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
            })
          Text($r("app.string.set_top"))
            .opacity(this.greyOpacity ? 0.4 : 1)
            .fontSize(10)
            .fontColor($r("app.color.set_top_font_color"))
            .padding({ top: 5 })
        }
        .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
        .width("25%")
        .height("100%")
        .opacity(this.greyOpacity ? 0.4 : 1)
        .enabled(this.greyOpacity ? false : true)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Image($r('app.media.delete'))
          .opacity(this.greyOpacity ? 0.4 : 1)
          .width(24)
          .height(24)
          .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
          .onClick(() => {
            this.noteDataDeleteDialogCtlBottom.open()
          })
        Text($r("app.string.delete"))
          .opacity(this.greyOpacity ? 0.4 : 1)
          .fontSize(10)
          .fontColor($r("app.color.delete_font_color"))
          .padding({ top: 5 })
      }
      .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
      .width("25%")
      .height("100%")
      .opacity(this.greyOpacity ? 0.4 : 1)
      .enabled(this.greyOpacity ? false : true)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      if (this.selectedFolderData.uuid != SysDefFolderUuid.RecentDeletes) {
        Column() {
          Image($r('app.media.move'))
            .opacity(this.greyOpacity ? 0.4 : 1)
            .width(24)
            .height(24)
            .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
            .onClick(() => {
              this.noteDataMoveDialogCtlBottom.open()
            })
          Text($r("app.string.move"))
            .opacity(this.greyOpacity ? 0.4 : 1)
            .fontSize(10)
            .fontColor($r("app.color.move_font_color"))
            .padding({ top: 5 })
        }
        .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
        .width("25%")
        .height("100%")
        .opacity(this.greyOpacity ? 0.4 : 1)
        .enabled(this.greyOpacity ? false : true)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }


      if (this.selectedFolderData.uuid == SysDefFolderUuid.RecentDeletes) {
        Column() {
          Image($r('app.media.recover'))
            .width(24)
            .height(24)
            .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
            .onClick(() => {
              this.CheckedNoteArray.forEach((noteItem) => {
                noteItem.is_deleted = Delete.No
                noteItem.deleted_time = 0
                prompt.showToast({ message: $r('app.string.restore').toString(), duration: 2000 })
                // update note to db
                let predicates_note = RdbStoreUtil.getRdbPredicates(TableName.NoteTable)
                predicates_note.equalTo(NoteTableColumn.Uuid, noteItem.uuid)
                RdbStoreUtil.update(noteItem.toNoteObject(), predicates_note, null)
              })
              this.longpress = false
              NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
              this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
            })
          Text($r("app.string.recover"))
            .fontSize(10)
            .fontColor($r("app.color.recover_font_color"))
            .padding({ top: 5 })
        }
        .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
        .width("25%")
        .height("100%")
        .opacity(this.greyOpacity ? 0.4 : 1)
        .enabled(this.greyOpacity ? false : true)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Image($r('app.media.check_all'))
          .width(24)
          .height(24)
          .responseRegion({ x: -15.0, y: -15.0, width: 54, height: 54 })
          .onClick(() => {
            if (this.CheckedNoteArray.length <
            NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid)
            .length) {
              NoteUtil.setAllNotesChecked(this.CheckedNoteArray, NoteUtil.getNoteDataArray(AppStorage.Get('AllNoteArray'), this.selectedFolderData.uuid))
            } else {
              NoteUtil.unsetAllNotesChecked(this.CheckedNoteArray)
            }
            this.refreshFlag = (this.refreshFlag == 0 ? 1 : 0)
          })
        Text($r("app.string.check_all"))
          .fontSize(10)
          .fontColor($r("app.color.check_all_font_color"))
          .padding({ top: 5 })
      }
      .backgroundColor($r('app.color.notelist_bgcolor_f1f3f5'))
      .width("25%")
      .height("100%")
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width("100%")
    .height(56)
    .visibility(this.longpress && this.portraitModel == true ? Visibility.Visible : Visibility.None)
  }
}
