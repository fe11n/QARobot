<template>
  <div class="appclass">
    <div class="maincontainer">
      <div class="appheader">
        <img src="@/assets/Euler.png" alt="" class="headerSrc" />
        <span class="title">欢迎使用欧拉小智</span>
      </div>
      <div class="container" id="container" ref="container">
        <div class="list" id="list" ref="list">
          <ul>
            <li v-for="(item, index) in msglist" :key="index">
              <RightItem :type="item.type" :content="item.content" v-if="item.me"></RightItem>
              <LeftItem :question="question" :type="item.type" :header="item.header" :content="item.content" :moreDoc="item.moreDoc" @badreq="badreq" @getMsg="getMsg" @chatover='chatover' @divMove="divMove" v-else>
              </LeftItem>
            </li>
          </ul>
        </div>
      </div>
      <div class="bottom">
        <ul id="list" class="poplist">
          <li class="popitem" v-for="(item, index) in msgData" :key="index" v-html="item"
            @click="popClick(item)"></li>
        </ul>
        <div class="input-send">
          <van-field :border="false" type="textarea" v-model="text"
            placeholder="请输入您要咨询的内容，小智会快速回复哒~" class="input" @input="searchData"
            @keydown.native="listen($event)" />
          <div class="bottomBtn">
            <el-button class="send" @click="send" :disabled="isDisabled">发送</el-button>
          </div>
        </div>
      </div>
    </div>
    <div class="aside">
      <div class="aside_header">常用工具</div>
      <div class="aside_content">
        <div class="aside_item" v-for="item in asideOrders" :key="item.title" @click="dialogVisible = true">
          <a>
            <div class="aside_item_content" style="display:flex;align-item:center;justify-content: center;">
              <img :src="item.src" />
            </div>
            <div class="">{{item.title}}</div>
          </a>
        </div>
      </div>
      <div class="aside_footer">
        <div class="footer_title">热点追踪</div>
        <div class="footer_content">
          <ul>
            <li class="itemmsg" v-for="item in hootList" :key="item.title" >
              <span @click="gethot(item.src)">{{ item.title }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <el-dialog
      title="意见反馈"
      :visible.sync="dialogVisible"
      center
      width="40%"
      @close="dialogClose">
      <div style="font-size: 16px;margin-bottom: 15px;">你给小智打几分？</div>
      <el-rate
        v-model="rate"
        show-text
        style="margin-bottom: 15px;">
      </el-rate>
      <el-input
        type="textarea"
        :rows="7"
        placeholder="请具体描述您的意见，小智会不断学习的"
        v-model="textarea">
      </el-input>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="feedback">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import defaultSettings from '@/config/defaultSettings.js';
import {asideOrders, hootList} from '@/config/asideData.js'
import { getAnswer, getSuggestions, getMoreDoc, getToken} from '@/api/post';
import LeftItem from '@/components/LeftItem';
import RightItem from '@/components/RightItem';

export default {
  name: 'Chat',
  components: { LeftItem, RightItem },
  data: () => {
    return {
      question: '',
      header: '',
      doneFlag: true,
      msgData: [],
      text: '',
      msg: '',
      msgType: '',
      msglist: [],
      moreDoc: [],
      rate: null,
      hootList: hootList,
      asideOrders: asideOrders,
      dialogVisible: false,
      textarea: ''
    };
  },
  updated() {
    //  dom 元素更新后执行滚动条到底部 否则不生效
    this.scrollToBottom()
  },
  computed: {
    isDisabled() {
      return (
        this.text.length === 0 || this.text.split(' ').join('').length === 0
      );
    },
  },
  created() {
    this.getToken()
  },
  mounted() {
    this.initData('welcome_tag');
  },
  methods: {
    // eventStream动态输出回答时实时监听滚动条底部距离并调用拖动方法
    divMove() {
      this.scrollToBottom()
    },
    scrollToBottom() { // 滚动条拖动最底部方法
      // this.$nextTick 将回调延迟到下次DOM更新循环之后执行。在修改数据之后立即使用它，然后等待DOM更新
      this.$nextTick(() => {
        // dom 元素更新后执行滚动条到底部 否则不生效
        let scrollElem = this.$refs.container;
        // console.log('scrollHeight: ', scrollElem.scrollHeight);
        // scrollElem.scrollTop = scrollElem.scrollHeight
        scrollElem.scrollTo({
          top: scrollElem.scrollHeight,
          behavior: 'smooth'
        });
      });
    },
    handleDraggable(config) {
      if (config.dragging) {
        this.style = {
          left: `${config.x}px`,
          top: `${config.y}px`,
          width: `${config.rect.width}px`,
          height: `${config.rect.height}px`,
        }
      }
    },
    gethot(path) {
      window.open(path)
    },
    feedback() {
      this.$message.info('反馈成功!')
      this.dialogVisible = false
    },
    getToken() {
      getToken(this.text).then((res) => {
        if (res) {
          localStorage.setItem('Access-Token', res.accessToken)
        }
      });
    },
    dialogClose() {
      this.textarea = '';
      this.rate = null;
    },
    listen(event) {
      this.text = this.text.replace(/[\r\n]/g, '');
      if (!this.text) {
        if (event.keyCode === 13) {
          event.preventDefault();
          return false;
        }
      }
      if (event.keyCode === 13) {
        event.preventDefault(); // 阻止浏览器默认换行操作
        this.send();
      }
    },
    chatover() {
      if (this.msgType === 4) {
        return
      } else {
        this.itempush()
      }
    },
    send() {
      this.msgData = [];
      this.text = this.text.replace(/[\r\n]/g, '');
      if (
        this.text.length === 0 ||
        this.text.split(' ').join('').length === 0
      ) {
        return;
      } else {
        this.msglist.push({
          type: 1,
          content: this.text,
          me: true,
        });
        this.initData(this.text);
        this.question = this.text
        this.text = '';
      }
    },
    popClick(msg) {
      msg = msg
        .replaceAll('<span style=\'color:#0C7DD4\'>', '')
        .replaceAll('</span>', '');
      this.text = msg;
      this.send();
      this.msgData = [];
    },
    searchData() {
      this.msgData = [];
      if (this.text) {
        getSuggestions(this.text).then((res) => {
          if (res.data) {
            res.data.forEach((item) => {
              if (this.text) {
                item = item.replaceAll(
                  this.text,
                  `<span style='color:#0C7DD4'>${this.text}</span>`
                );
                this.msgData.push(item);
              }
            });
          }
        });
      }
    },
    itempush() {
      this.msglist.push({
        header: this.header,
        type: this.msgType,
        content: this.msg,
        moreDoc: this.moreDoc,
        me: false,
      });
    },
    initData(text) {
      if (this.doneFlag) {
        this.doneFlag = false;
        setTimeout(() => {
          this.doneFlag = true;
        }, defaultSettings.DefaultRequestInterval);
        getMoreDoc(text).then((res) => {
          if (res.status === 200 && res.obj) {
            this.moreDoc = [];
            res.obj.records.forEach((item) => {
              item.title = item.title.replaceAll(
                '<span>',
                '<span style="color:#AD0D00">'
              );
              this.moreDoc.push(item);
            });
          } else {
            this.moreDoc = [];
          }
        })
        getAnswer(text).then((res) => {
          if (res.data && res.data[0]) {
            this.header = '';
            if (res.data[0].answer_source === 'welcome_tag') {
              this.msgType = 0; // 首次进入小智界面所展示的数据类型
              this.msg = res.data[0].chatScriptContent;
            } else if (res.data[0].answer_source === 'backfill' && this.moreDoc.length !== 0) {
              this.msgType = 1; // 小智未查找到问题相关信息所返回的数据类型
              this.msg = '小智对openEuler社区及openEuler操作系统比较了解~可以尝试问问我相关问题哦';
            } else if (
              res.data[0].answer_source === 'faq' &&
              res.data[0].answer
            ) {
              this.msgType = 2; // 小智查找到问题相关信息所返回的数据类型
              this.msg = res.data[0].answer;
              this.header = res.data[0].intent;
            } else if (res.data[0].answer_source === 'backfill' && this.moreDoc.length === 0) {
              this.msgType = 4;
              this.msg = '';
            } else {
              this.msgType = 3; //
              this.msg = res.data[0].related_ques;
            }
            if (this.msgType === 0 || this.msgType === 2 || this.msgType === 4) {
              this.itempush()
            } else {
              this.msglist.push({
                header: this.header,
                type: 4,
                content: '',
                moreDoc: this.moreDoc,
                me: false,
              });
            }
          }
        });
      } else {
        this.$message('您的操作过于频繁,请稍后再试');
        return;
      }
    },
    getMsg(msg) {
      this.text = msg;
      this.send();
    },
    badreq() {
      this.msglist.push({
        header: '可以告诉我您不满意的原因吗?',
        type: 5,
        content: '',
        moreDoc: [],
        me: false,
      });
    }
  },
};
</script>
<style scoped>
</style>
<style scoped lang="scss">
.appclass {
  display: flex;
  .maincontainer {
  width: 889px;
  height: 788px;
  background: #ffffff;
  box-shadow: 0px 0px 14px rgba(51, 51, 51, 0.16);
  opacity: 1;
  border-radius: 0px;
  margin: 88px auto 24px;
  margin-right: 20px;
  .appheader {
    width: 889px;
    height: 8%;
    background: #afdfff;
    opacity: 1;
    // display: fixed;
    vertical-align: middle;
    .headerSrc {
      position: relative;
      width: 48px;
      height: 48px;
      margin: 8px 803px 8px 38px;
    }
    .title {
      width: 202px;
      height: 31px;
      font-size: 24px;
      font-family: Microsoft YaHei;
      font-weight: bold;
      margin: 15px 581px 16px 106px !important;
      color: #333333;
      position: relative;
      top: -50px;
    }
  }
  .container {
    height: 70%;
    overflow: auto;
    &:hover {
      overflow-y: auto;
    }

    &::-webkit-scrollbar {
      width: 6px;
      color: transparent;
    }

    &::-webkit-scrollbar-track {
      margin: -25px 0 -25px 0;
      border-radius: 5px;
    }

    &::-webkit-scrollbar-thumb {
      background-color: rgba(136, 153, 152, 0.3);
      border-radius: 5px;
    }

    &::-webkit-scrollbar-button {
      background-color: transparent;
      border-radius: 5px;
    }
    ul {
      padding: 0;
      margin: 0;
    }

    li {
      list-style: none;
    }

    .list {
      width: 100%;
    }
  }
  ::v-deep .bottom {
    position: relative;
    height: 173px;
    border-top: 1px solid #b7b7b7;
    .poplist {
      border: 1px solid #c1c1c1;
      border-radius: 4px;
      margin-left: 19px;
      background: #fbfbfb;
      position: absolute;
      z-index: 1;
      bottom: 100%;
      font-size: 14px;
      font-family: Microsoft YaHei UI;
      font-weight: 400;
      color: #333333;
      .popitem {
        padding: 5px 40px;
        cursor: pointer;
      }
      .popitem:hover {
        background: #e5e8f0;
      }
    }
    .input-send {
      .input {
        height: 129px;
        .van-field__control {
          min-height: 112px !important;
          &:hover {
            overflow-y: auto;
          }

          &::-webkit-scrollbar {
            width: 7px;
            color: transparent;
          }

          &::-webkit-scrollbar-track {
            margin: -25px 0 -25px 0;
            border-radius: 5px;
          }

          &::-webkit-scrollbar-thumb {
            background-color: rgba(136, 153, 152, 0.3);
            border-radius: 5px;
          }

          &::-webkit-scrollbar-button {
            background-color: transparent;
            border-radius: 5px;
          }
        }
      }
      .bottomBtn {
        .send {
          position: relative;
          right: -808px;
          width: 76px;
          height: 36px;
          border: 0;
          background: #eeeeee;
          border-radius: 4px;
        }
      }
    }
  }
  }
  .aside {
    width: 300px;
    height: 788px;
    background: #ffffff;
    box-shadow: 0px 0px 14px rgba(51, 51, 51, 0.16);
    opacity: 1;
    border-radius: 0px;
    margin: 88px auto 24px;
    margin-left: 20px;
    .aside_header {
      font-weight: 700;
      font-family: Microsoft YaHei;
      font-size: 20px;
      color: #000;
      line-height: 29px;
      text-align: center;
      margin: 18px 25px 16px 24px;
      display: inline-block;
    }
    .aside_content {
      display: flex;
      flex-wrap: wrap;
      margin: 0 15px 0;
      .aside_item {
        flex: 0 0 33.3%;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        margin-top: 16px;
        margin-bottom: 16px;
        a {
          background: 0 0;
          text-decoration: none;
          outline: 0;
          cursor: pointer;
          transition: color .2s ease;
          .aside_item_content {
            display: flex;
            justify-content: center;
            margin-bottom: 10px;
          }
          div {
            font-size: 15px;
            color: #555;
            letter-spacing: 0;
            text-align: center;
            line-height: 18px;
          }
        }
      }
    }
    .aside_footer {
      margin: 18px 25px 16px 24px;
      .footer_title {
        font-weight: 700;
        font-family: Microsoft YaHei;
        font-size: 20px;
        color: #000;
        line-height: 29px;
        text-align: center;
        display: inline-block;
        margin-bottom: 10px;
      }
      .footer_content {
        .itemmsg {
          color: #0064c8;
          margin-top: 10px;
          font-size: 16px;
          margin: 15px auto 15px;
          cursor: pointer;
          font-family: Microsoft Yahei,Open Sans,Helvetica,Tahoma,Arial,Hiragino Sans GB,WenQuanYi Micro Hei,sans-serif;
          &:hover {
            text-decoration: underline;
          }
        }
      }
    }
  }
}
</style>